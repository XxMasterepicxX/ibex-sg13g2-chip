# Release GDS for the IHP Open-Silicon MPW: the filled chip with its top cell renamed to the generated IP name.
# usage: klayout -b -r release_gds.py -rd in_gds=... -rd top=... -rd name=... -rd out_gds=...
import pya
layout = pya.Layout()
layout.read(in_gds)
cell = layout.cell(top)
assert cell is not None and cell.is_top(), 'top cell %s not found' % top
assert layout.cell(name) is None, 'a cell named %s already exists' % name
cell.name = name
opt = pya.SaveLayoutOptions()
opt.format = 'GDS2'
opt.dbu = 0.001
opt.scale_factor = 1.0
opt.write_context_info = False
opt.gds2_libname = 'LIB'
opt.gds2_max_cellname_length = 32000
opt.gds2_max_vertex_count = 8000
opt.gds2_multi_xy_records = False
opt.gds2_write_cell_properties = False
opt.gds2_write_file_properties = False
opt.gds2_resolve_skew_arrays = False
opt.gds2_no_zero_length_paths = True
opt.gds2_write_timestamps = True
layout.write(out_gds, opt)
print('RELEASE_GDS', out_gds, 'top', name, 'dbu', layout.dbu, 'cells', layout.cells())
