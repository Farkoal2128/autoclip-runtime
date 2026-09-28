"""Derive an immutable review successor from pinned base bytes and committed source."""
import argparse
import hashlib
import importlib.util
import json
import subprocess
import tempfile
import zipfile
from pathlib import Path


def sha(data):
    return hashlib.sha256(data).hexdigest()


def encoded(value):
    return (json.dumps(value, indent=2) + '\n').encode()


def build(base, expected_base, repo, revision, release_id, output, installer,
          inventory_only=True, notice_only=False):
    if notice_only and not inventory_only:
        raise ValueError('C7 notice correction cannot refresh other review material')
    if output.exists() or installer.exists():
        raise ValueError('Refusing to replace immutable outputs')
    if sha(base.read_bytes()) != expected_base:
        raise ValueError('Base archive differs from exact review identity')
    revision = subprocess.check_output(['git','rev-parse',revision],cwd=repo,text=True).strip()
    def committed(name):
        return subprocess.check_output(['git','show',revision+':'+name],cwd=repo)
    # Materialize the committed recipe and data, avoiding checkout newline conversion.
    recipe_directory = tempfile.TemporaryDirectory(prefix='autoclip-committed-recipe-')
    recipe_root = Path(recipe_directory.name)
    recipe = recipe_root/'scripts/build-source-routed-release.py'
    recipe.parent.mkdir()
    for name in ('scripts/build-source-routed-release.py','review-license-normalization.json'):
        (recipe_root/name).write_bytes(committed(name))
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
        base_legal_runtime_commit=legal['runtime_commit']
        changes={}
        names=('install-source-build.ps1','update.ps1','cuda-prerequisites.ps1',
               'Prepare-AutoClipOfflineCache.ps1','prerequisite-terms.ps1',
               'prerequisite-terms.json','review-license-normalization.json',
               'scripts/build-source-routed-release.py','scripts/build-review-successor.py',
               'build-native-from-source.ps1','upstream-assets.ps1',
               'review-component-corrections.json')
        if notice_only:
            names+=('review-static-runtime-notices.json',)
        source_hashes={}
        for name in names:
            data=committed(name); source_hashes[name]=sha(data)
            if '/' not in name:
                changes[name]=data
            changes['notices-and-source/build-provenance/current/'+name]=data
        manifest['native_build'].update(runtime_commit=revision,candidate_source_state='committed_runtime_source')
        packet_manifest=json.loads(source.read('notices-and-source/sbom-packet-manifest.json'))
        if inventory_only:
            corrections=json.loads(committed('review-component-corrections.json'))
            for item in corrections['files']:
                data=committed(item['path'])
                if len(data)!=item['bytes'] or sha(data)!=item['sha256'] or data!=source.read(item['destination']):
                    raise ValueError('Inventory-only successor changes reviewed component evidence')
                source_hashes[item['path']]=sha(data)
            module.validate_native_component_routes(legal['packages']+legal['external_assets'],corrections['native_routes'],source.read)
            module.synchronize_sbom_index(json.loads(source.read('notices-and-source/sbom-component-index.json')),json.loads(source.read('notices-and-source/sbom-component-plan.json')))
        if not inventory_only:
            legal.update(runtime_commit=revision,candidate_source_state='committed_runtime_source',native_build=dict(manifest['native_build']))
            for package in legal['packages']:
                prefix='notices-and-source/wheel-notices/'+package['filename']+'/'
                module.normalize_license_row(package,lambda name: source.read(prefix+name))
            index=json.loads(source.read('notices-and-source/sbom-component-index.json'))
            plan=json.loads(source.read('notices-and-source/sbom-component-plan.json'))
            corrections=json.loads(committed('review-component-corrections.json'))
            for item in corrections['files']:
                data=committed(item['path'])
                if len(data)!=item['bytes'] or sha(data)!=item['sha256']:
                    raise ValueError('Component evidence differs: '+item['path'])
                changes[item['destination']]=data
                source_hashes[item['path']]=sha(data)
            for rule in corrections['sbom_branches']:
                rows=[r for r in plan['components'] if (r['wheel'],r['wheel_sha256'],r['purl'])==(rule['wheel'],rule['wheel_sha256'],rule['purl'])]
                if len(rows)!=1 or rows[0]['expressions'][0]['original']!=rule['original']:
                    raise ValueError('Reviewed SBOM identity/original differs')
                if rule['selected'] not in rule['original'].split(' OR '):
                    raise ValueError('Selected branch is not offered')
                if sha(source.read(rule['grant']['path']))!=rule['grant']['sha256']:
                    raise ValueError('Reviewed SBOM grant differs')
                expression=rows[0]['expressions'][0]
                expression.setdefault('previous_selected',expression['selected'])
                expression.update(selected=rule['selected'],licenses=[rule['selected']],selection_status='Exact offered grant branch; independent successor disposition pending')
                rows[0]['license_evidence']=[rule['grant']]
            artifacts=legal['packages']+legal['external_assets']
            for rule in corrections['native_routes']:
                rows=[r for r in artifacts if r['sha256']==rule['artifact_sha256']]
                if len(rows)!=1:
                    raise ValueError('Reviewed native artifact identity differs')
                rows[0]['components']=[c for c in rows[0].get('components',[]) if c['name']!=rule['component']]+[rule['mapping']]
            module.validate_native_component_routes(artifacts,corrections['native_routes'],lambda name: changes.get(name) or source.read(name))
            module.synchronize_sbom_index(index,plan)
            changes['notices-and-source/sbom-component-index.json']=encoded(index)
            changes['notices-and-source/sbom-component-plan.json']=encoded(plan)
            packet_manifest=json.loads(source.read('notices-and-source/sbom-packet-manifest.json'))
            module.refresh_packet_manifest(packet_manifest,lambda name: changes.get(name) or source.read(name))
            changes['notices-and-source/sbom-packet-manifest.json']=encoded(packet_manifest)
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
        if notice_only:
            rule=json.loads(committed('review-static-runtime-notices.json'))
            if rule.get('schema_version') != 1 or len(rule.get('notices', [])) != 2:
                raise ValueError('C7 notice rule differs from reviewed scope')
            matches=[row for row in legal['external_assets'] if row.get('sha256') == rule['artifact_sha256']]
            if (len(matches) != 1 or matches[0].get('member_path') != rule['member_path']
                    or matches[0].get('member_sha256') != rule['member_sha256']):
                raise ValueError('C7 external OpenBLAS identity differs')
            external=matches[0]
            if {row['component'] for row in rule['notices']} != {'mingw-w64-runtime','winpthreads'}:
                raise ValueError('C7 component set differs from reviewed scope')
            for notice in rule['notices']:
                data=committed(notice['source_path'])
                if len(data) != notice['bytes'] or sha(data) != notice['sha256']:
                    raise ValueError('C7 notice differs from pinned upstream bytes: '+notice['component'])
                if notice['path'] in source.namelist() or notice['path'] in changes:
                    raise ValueError('C7 notice would overwrite an existing member: '+notice['path'])
                source_hashes[notice['source_path']]=sha(data)
                changes[notice['path']]=data
                external.setdefault('components', []).append(dict(
                    name=notice['component'], version_scope=notice['version_scope'],
                    binary_path=rule['member_path'], binary_sha256=rule['member_sha256'],
                    license_paths=[dict(path=notice['path'],sha256=notice['sha256'])],
                    source_evidence=dict(path=notice['source_path'],url=notice['url'],
                                         upstream_path=notice['upstream_path'],
                                         bytes=notice['bytes'],sha256=notice['sha256']),
                    relationship='Conservatively mapped to the exact external OpenBLAS DLL; separate from OpenBLAS BSD and GCC runtime texts',
                    fulfillment_status='exact_notice_delivered_focused_independent_review_pending'))
            legal.update(runtime_commit=revision,candidate_source_state='committed_runtime_source',
                         native_build=dict(manifest['native_build']))
            changes['notices-and-source/legal-index.json']=encoded(legal)
            module.validate_static_runtime_notice_routes(
                legal['external_assets'],[rule],lambda name: changes.get(name) or source.read(name))
            changes['notices-and-source/MANIFEST.md']=(
                source.read('notices-and-source/MANIFEST.md')+
                ('\n\n## '+release_id+' external OpenBLAS static runtime notices\n\n'+
                 'The external `OpenBLAS-0.3.30-x64.zip!/bin/libopenblas.dll` has separate '+
                 'MinGW-w64 v8.0.0 runtime and winpthreads notices under `component-evidence/`. '+
                 'See `legal-index.json` for exact DLL association and notice hashes. '+
                 'Focused independent C7 disposition remains pending.\n').encode())
        provenance=json.loads(source.read('notices-and-source/build-provenance.json'))
        provenance.update(runtime_commit=revision,source_state='committed_runtime_source',construction_base_archive_sha256=expected_base,committed_source_sha256=source_hashes)
        if inventory_only:
            provenance['reviewed_material_carry_forward']=dict(
                base_runtime_commit=base_legal_runtime_commit,
                legal_index_sha256=sha(source.read('notices-and-source/legal-index.json')),
                scope='Exact unchanged reviewed legal/SBOM bytes; original source attribution retained; no new clearance')
            if notice_only:
                provenance['reviewed_material_carry_forward']['scope']=(
                    'Unchanged SBOM, source, app, native and terms bytes carried forward; '
                    'only C7 notices, the external OpenBLAS legal mapping and dependent metadata transformed; '
                    'focused independent disposition pending')
                provenance['c7_notice_rule_sha256']=sha(committed('review-static-runtime-notices.json'))
        changes['notices-and-source/build-provenance.json']=encoded(provenance)
        if not inventory_only:
            changes['notices-and-source/MANIFEST.md']=source.read('notices-and-source/MANIFEST.md')+f'\n\n## {release_id}\n\nCurrent runtime source `{revision}`. Current source snapshots are under build-provenance/current. Earlier snapshots retain historical scope. Review metadata and prerequisite consent corrected; independent final disposition pending.\n'.encode()
        apps=[n.split('/')[-1] for n in source.namelist() if n.startswith('wheelhouse/') and n.endswith('.whl')]
        inventory=module.distribution_inventory(manifest, apps)
        changes['distribution-inventory.json']=encoded(inventory)
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
        module.validate_distribution_inventory(json.loads(target.read('distribution-inventory.json')),json.loads(target.read('release-manifest.json')),apps)
        if notice_only:
            module.validate_static_runtime_notice_routes(
                json.loads(target.read('notices-and-source/legal-index.json'))['external_assets'],
                [rule], target.read)
        for row in packet_manifest['files']:
            raw=target.read(row['path'])
            if len(raw)!=row['bytes'] or sha(raw)!=row['sha256']:
                raise ValueError('Successor auxiliary manifest mismatch: '+row['path'])
    with zipfile.ZipFile(output) as target:
        result=dict(release_id=release_id,runtime_commit=revision,archive_sha256=sha(output.read_bytes()),archive_bytes=output.stat().st_size,manifest_sha256=sha(encoded(manifest)),installer_sha256=sha(installer.read_bytes()),legal_index_sha256=sha(target.read('notices-and-source/legal-index.json')),distribution_inventory_sha256=sha(target.read('distribution-inventory.json')),provenance_sha256=sha(target.read('notices-and-source/build-provenance.json')),indexed_files=len(indexed),members=len(indexed)+1)
    (output.parent/'identities.json').write_bytes(encoded(result))
    recipe_directory.cleanup()
    return result


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for name in ('base','repo','output','installer'):p.add_argument('--'+name,type=Path,required=True)
    for name in ('expected-base','revision','release-id'):p.add_argument('--'+name,required=True)
    p.add_argument('--refresh-review-material',action='store_true',help='Explicitly transform legal/SBOM material; default preserves reviewed bytes')
    p.add_argument('--apply-c7-notices',action='store_true',help='Apply only the pinned MinGW-w64 notice correction')
    a=p.parse_args()
    print(json.dumps(build(a.base,a.expected_base,a.repo,a.revision,a.release_id,a.output,a.installer,
                          inventory_only=not a.refresh_review_material,
                          notice_only=a.apply_c7_notices),indent=2))
