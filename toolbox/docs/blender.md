# Blender

<!-- vim-markdown-toc GFM -->

* [TODO](#todo)
* [Scripts](#scripts)
    * [Selected objects to ground](#selected-objects-to-ground)
* [Add-Ons](#add-ons)

<!-- vim-markdown-toc -->

## TODO

- [MeasureIt](https://www.youtube.com/watch?v=R0jCdCoaRvs)
- [Modeling with metric units](https://blender.stackexchange.com/questions/67526/modeling-with-metric-units-cm)
- Placing an object on the ground (from https://blender.stackexchange.com/a/116149)
  - In Edit Mode select the bottom vertex, edge or face
  - From the ShiftS menu, choose 'Cursor to Selected'
  - In Object Mode, ShiftCtrlAltC, 'Set Origin to Cursor'
  - Still in Object Mode, in the properties region of the 3D View (toggled by N,) in the 'Transform' panel, set Location Z to 0
- [Create a cone](https://blender.stackexchange.com/questions/3603/how-can-i-transform-one-end-of-a-cylindrical-extrusion-to-create-a-cone-or-needl)
- [Cut a shape out](https://blender.stackexchange.com/questions/7928/how-would-you-cut-a-shape-out-of-an-object-using-another-object)
- [Cutting a mesh in half](https://blender.stackexchange.com/questions/5320/cutting-a-mesh-in-half)
- [Isolate or hide specific parts of an object in edit mode](https://blender.stackexchange.com/questions/6890/isolate-or-hide-specific-parts-of-an-object-in-edit-mode)
- [Splitting pieces of a mesh into a new object](https://blender.stackexchange.com/questions/6184/splitting-pieces-of-a-mesh-into-a-new-object)
- [Knife and Bisect Tools (Blender 2.8)](https://www.youtube.com/watch?v=cpb8-YqaBTM)
- Zoom Rectangle: <kbd>Shift</kbd> + <kbd>B</kbd>
- Splitting mesh at edges
  - Select the edges where you want to have it cut (Your edges should have a closed loop)
  - Go to Mesh > Edges (<kbd>Ctrl</kbd> + <kbd>E</kbd>) > Edge Split
  - Change to face selection mode and select on of the faces on a side and type <kbd>Ctrl</kbd> + <kbd>L</kbd> to select linked faces
  - Then type <kbd>P</kbd> and confirm Separate Selection
- [How to merge two unconnected edges into a single one](https://blender.stackexchange.com/questions/44953/how-to-merge-two-unconnected-edges-into-a-single-one)
- Move vertex of one object to the same position of a vertex of another object
  - Set origin of object A to vertex a
  - Set cursor to vertex b of object B (Select vertex b and the choose "Cursor to Selection")
  - Select object A
  - <kbd>Shift</kbd> + <kbd>S</kbd> "Selection to Cursor"

## Scripts

### Selected objects to ground

    # from https://blender.stackexchange.com/a/117188
    import bpy
    context = bpy.context

    for obj in context.selected_objects:
        mx = obj.matrix_world
        minz = min((mx * v.co)[2] for v in obj.data.vertices)
        mx.translation.z -= minz

## Add-Ons

- MeasureIt
- LoopTools
- Pie Menu Official
- Mesh: 3D Print Toolbox
