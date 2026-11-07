import bpy, pathlib, json, math, sys
from mathutils import Vector
root=pathlib.Path(sys.argv[sys.argv.index('--')+1]).resolve()
if (root/'artwork'/'head-icon-v001.png').exists():
    raise RuntimeError('Reference v001 already exists; choose a new version before rendering')
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
manifest=json.loads((root/'source/gltf-v001/manifest.json').read_text(encoding='utf-8'))
def load_asset(item):
    name=pathlib.PurePosixPath(item['output'].replace('\\','/')).name
    group='models' if item['role']=='main' else 'attachments'
    paths=list((pathlib.Path('.tools/character-artwork-stage')/root.name/group).rglob(name))
    if not paths: return []
    before=set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(paths[0]))
    return [obj for obj in bpy.data.objects if obj not in before]
main=next(x for x in manifest['assets'] if x['role']=='main' and x.get('output'))
objects=load_asset(main)
body=next((o for o in objects if o.type=='ARMATURE'),None)
print('BODY',body.name if body else 'NONE',flush=True)
if body:
    idle = next((a for a in bpy.data.actions if 'idle' in a.name.lower()), None)
    if idle:
        body.animation_data_create().action = idle
        bpy.context.scene.frame_set(10)
        bpy.context.view_layer.update()
        print('POSE', idle.name, flush=True)
# Match the previously used one-pose attachment method, not a runtime rig.
for item in manifest['assets']:
    if item.get('role')!='attachment' or not item.get('output'): continue
    for obj in load_asset(item):
        if obj.type=='ARMATURE' and body:
            for bone in obj.pose.bones:
                src=body.pose.bones.get(bone.name)
                if src:
                    bone.matrix=obj.matrix_world.inverted() @ body.matrix_world @ src.matrix
                    bpy.context.view_layer.update()
# World bounds for framing the actual imported geometry.
deps=bpy.context.evaluated_depsgraph_get(); coords=[]
for obj in bpy.data.objects:
    if obj.type=='MESH':
        evaluated=obj.evaluated_get(deps)
        coords.extend(evaluated.matrix_world @ Vector(c) for c in evaluated.bound_box)
if not coords: raise RuntimeError('No meshes')
low=Vector(tuple(min(p[i] for p in coords) for i in range(3)))
high=Vector(tuple(max(p[i] for p in coords) for i in range(3)))
center=(low+high)/2; extent=high-low; scale=max(extent)*1.3
print('BOUNDS',list(low),list(high),flush=True)
scene=bpy.context.scene; scene.render.engine='CYCLES'; scene.cycles.samples=16
scene.render.resolution_x=512; scene.render.resolution_y=512; scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'; scene.render.film_transparent=True
scene.world.color=(0.32,0.32,0.32)
def point(obj,target): obj.rotation_euler=(target-obj.location).to_track_quat('-Z','Y').to_euler()
def light(position,energy,size):
    data=bpy.data.lights.new('Area','AREA'); data.energy=energy; data.shape='DISK'; data.size=size
    obj=bpy.data.objects.new('Area',data); scene.collection.objects.link(obj); obj.location=center+Vector(position)*scale; point(obj,center)
light((3,-4,5),12000*scale*scale/25,scale*2);light((-3,-1,3),7000*scale*scale/25,scale*2)
cam_data=bpy.data.cameras.new('Camera'); cam=bpy.data.objects.new('Camera',cam_data); scene.collection.objects.link(cam); scene.camera=cam; cam_data.type='ORTHO'; cam_data.ortho_scale=scale
output=root/'artwork'; output.mkdir(exist_ok=True)
for label,direction in [('front',(0,-1,.15)),('side',(1,0,.15)),('back',(0,1,.15)),('stance',(-1,0,.15))]:
    cam.location=center+Vector(direction).normalized()*scale*3; point(cam,center)
    scene.render.filepath=str(output/('check-'+label+'-v001.png')); bpy.ops.render.render(write_still=True)

head_bone = None
if body:
    head_bone = next((b for b in body.pose.bones if b.name.lower() in ('head','head_0','head1','bip_head')), None)
    if head_bone is None:
        head_bone = next((b for b in body.pose.bones if 'head' in b.name.lower() and 'hair' not in b.name.lower()), None)
head_target = body.matrix_world @ head_bone.head if head_bone else center + Vector((0,0,extent.z*0.25))
print('HEAD',head_bone.name if head_bone else 'bounds estimate',list(head_target),flush=True)
cam_data.ortho_scale=scale*0.45
cam.location=head_target+Vector((0,-1,.10)).normalized()*scale*3
point(cam,head_target)
scene.render.filepath=str(output/'head-icon-v001.png'); bpy.ops.render.render(write_still=True)
