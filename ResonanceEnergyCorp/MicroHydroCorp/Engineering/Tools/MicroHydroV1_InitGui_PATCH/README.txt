MicroHydroV1 InitGui Patch (macOS)

What this fixes
- FreeCAD log shows: [MHV1][InitGui] Base: /
  That makes the add-on look for /icons, /macros, /QA, /Drawings, /CFD and fail.
- This patched InitGui.py resolves BASE to the actual add-on folder, never '/'.

Install
1) Quit FreeCAD.
2) Copy MicroHydroV1/InitGui.py from this ZIP into:
   ~/Library/Application Support/FreeCAD/Mod/MicroHydroV1/InitGui.py
   (Overwrite the existing file.)
3) Start FreeCAD and check Report View:
   [MHV1][InitGui] Base: /Users/.../Library/Application Support/FreeCAD/Mod/MicroHydroV1
   SELF-TEST entries should show OK (assuming icons/macros/QA/Drawings/CFD exist).

Optional override
- You can force a base path by setting:
    export MICROHYDRO_MHV1_BASE="$HOME/Library/Application Support/FreeCAD/Mod/MicroHydroV1"
