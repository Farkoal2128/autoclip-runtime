"""Derive an immutable review successor from pinned base bytes and committed source."""
import argparse
import hashlib
import importlib.util
import json
import subprocess
import zipfile
from pathlib import Path


def sha(data):
    return hashlib.sha256(data).hexdigest()


def encoded(value):
    return (json.dumps(value, indent=2) + '\n').encode()


def build(base, expected_base, repo, revision, release_id, output, installer):
    if output.exists() or installer.exists():
        raise ValueError('Refusing to replace immutable outputs')
    if sha(base.read_bytes()) != expected_base:
        raise ValueError('Base archive differs from exact review identity')
    revision = subprocess.check_output(['git','rev-parse',revision],cwd=repo,text=True).strip()
    def committed(name):
        return subprocess.check_output(['git','show',revision+':'+name],cwd=repo)
    # Execute only the named recipe from the revision; resolve reviewed rule data
    # against this checkout and assert both match the committed inputs.
    recipe = repo/'scripts/build-source-routed-release.py'
    for name in ('scripts/build-source-routed-release.py','review-license-normalization.json'):
        if (repo/name).read_bytes() != committed(name):
            raise ValueError('Checkout does not match committed review recipe: '+name)
    spec=importlib.util.spec_from_file_location('review_recipe',recipe)
    module=importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
    with zipfile.ZipFile(base) as source:
        if len(source.namelist()) != len(set(source.namelist())):
            raise ValueError('Duplicate base ZIP members')
        manifest=json.loads(source.read('release-manifest.json'))
        for row in manifest['files']:
            raw=source.read(row['path'])
            if len(raw)!=row['bytes'] or sha(raw)!=row['sha256']:
                raise ValueError('Base manifest mismatch: '+row['path'])
        legal=json.loads(source.read('notices-and-source/legal-index.json'))
        changes={}
        names=('install-source-build.ps1','update.ps1','cuda-prerequisites.ps1',
               'Prepare-AutoClipOfflineCache.ps1','prerequisite-terms.ps1',
               'prerequisite-terms.json','review-license-normalization.json',
               'scripts/build-source-routed-release.py','scripts/build-review-successor.py',
               'build-native-from-source.ps1','upstream-assets.ps1')
        source_hashes={}
        for name in names:
            data=committed(name); source_hashes[name]=sha(data)
            if '/' not in name:
                changes[name]=data
            changes['notices-and-source/build-provenance/current/'+name]=data
        manifest['native_build'].update(runtime_commit=revision,candidate_source_state='committed_runtime_source')
        legal.update(runtime_commit=revision,candidate_source_state='committed_runtime_source',native_build=dict(manifest['native_build']))
        for package in legal['packages']:
            prefix='notices-and-source/wheel-notices/'+package['filename']+'/'
            module.normalize_license_row(package,lambda name: source.read(prefix+name))
        index=json.loads(source.read('notices-and-source/sbom-component-index.json'))
        plan=json.loads(source.read('notices-and-source/sbom-component-plan.json'))
        module.synchronize_sbom_index(index,plan)
        changes['notices-and-source/sbom-component-index.json']=encoded(index)
        # Preserve the exact app supplement while making the FlatBuffers route explicit.
        import io
        app=next(p for p in legal['packages'] if p['normalized_name']=='autoclip')
        with zipfile.ZipFile(io.BytesIO(source.read('wheelhouse/'+app['filename']))) as wheel:
            supplement=wheel.read('autoclip/assets/licenses/python-runtime-notices.txt')
        if b'===== flatbuffers@25.12.19 =====' not in supplement or b'cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30' not in supplement:
            raise ValueError('Exact FlatBuffers supplement is absent')
        location='notices-and-source/supplements/python-runtime-notices.txt'
        changes[location]=supplement
        flat=next(p for p in legal['packages'] if p['normalized_name']=='flatbuffers')
        flat['supplement_evidence']=dict(path=location,sha256=sha(supplement),component='flatbuffers@25.12.19',license_expression='Apache-2.0',scope='Exact delivered supplement; independent attribution/applicability review pending')
        changes['notices-and-source/legal-index.json']=encoded(legal)
        provenance=json.loads(source.read('notices-and-source/build-provenance.json'))
        provenance.update(runtime_commit=revision,source_state='committed_runtime_source',construction_base_archive_sha256=expected_base,committed_source_sha256=source_hashes)
        changes['notices-and-source/build-provenance.json']=encoded(provenance)
        changes['notices-and-source/MANIFEST.md']=source.read('notices-and-source/MANIFEST.md')+f'\n\n## {release_id}\n\nCurrent runtime source `{revision}`. Current source snapshots are under build-provenance/current. Earlier snapshots retain historical scope. Review metadata and prerequisite consent corrected; independent final disposition pending.\n'.encode()
        indexed={r['path']:r for r in manifest['files']}
        for name,data in changes.items():
            indexed[name]=dict(path=name,bytes=len(data),sha256=sha(data))
        manifest['files']=[indexed[n] for n in sorted(indexed)]
        changes['release-manifest.json']=encoded(manifest)
        with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as target:
            for entry in source.infolist():
                target.writestr(entry,changes.pop(entry.filename,source.read(entry.filename)))
            for name,data in sorted(changes.items()):
                target.writestr(name,data)
    template=committed('install-source-build.ps1').decode()
    for helper in ('prerequisite-terms.ps1','cuda-prerequisites.ps1'):
        template=template.replace(". (Join-Path $PSScriptRoot '"+helper+"')",'# Helper embedded in standalone installer.')
    embedded="$script:EmbeddedPrerequisiteTerms = @'\n"+committed('prerequisite-terms.json').decode()+"\n'@\n"
    for helper in ('upstream-assets.ps1','prerequisite-terms.ps1','cuda-prerequisites.ps1'):
        embedded+=committed(helper).decode()+'\n'
    template=template.replace("$ErrorActionPreference = 'Stop'","$ErrorActionPreference = 'Stop'\n"+embedded,1)
    for old,new in [('de757f19171bbc57b6c26e31f7431a62240e2a4ee081167f649963bf61f29500',sha(output.read_bytes())),('f28fcc93e9f7d46c2f947c0d199d20b2e415de4d328eeeed961173bb5373772d',sha(encoded(manifest))),('v11-20260926-source-build-candidate-v14',release_id)]:
        if template.count(old)!=1:
            raise ValueError('Installer pin is not unique: '+old)
        template=template.replace(old,new)
    installer.write_text(template,encoding='utf-8')
    with zipfile.ZipFile(output) as target:
        if len(target.namelist())!=len(set(target.namelist())) or set(target.namelist())!=set(indexed)|{'release-manifest.json'}:
            raise ValueError('Successor archive membership mismatch')
        for row in manifest['files']:
            raw=target.read(row['path'])
            if len(raw)!=row['bytes'] or sha(raw)!=row['sha256']:
                raise ValueError('Successor archive hash mismatch: '+row['path'])
    result=dict(release_id=release_id,runtime_commit=revision,archive_sha256=sha(output.read_bytes()),archive_bytes=output.stat().st_size,manifest_sha256=sha(encoded(manifest)),installer_sha256=sha(installer.read_bytes()),legal_index_sha256=sha(encoded(legal)),indexed_files=len(indexed),members=len(indexed)+1)
    (output.parent/'identities.json').write_bytes(encoded(result))
    return result


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for name in ('base','repo','output','installer'):p.add_argument('--'+name,type=Path,required=True)
    for name in ('expected-base','revision','release-id'):p.add_argument('--'+name,required=True)
    a=p.parse_args()
    print(json.dumps(build(a.base,a.expected_base,a.repo,a.revision,a.release_id,a.output,a.installer),indent=2))
