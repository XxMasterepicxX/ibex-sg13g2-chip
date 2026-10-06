# IHP SG13G2 (IHP-Open-PDK 5e6d592). Everything the Synopsys flow needs to know about the PDK.
# The flow scripts contain no layer names, cell names or rule values of their own.
set PDK_NAME   ihp_sg13g2
set PDK_ROOT   $env(HOME)/flash/pdk/IHP-Open-PDK/ihp-sg13g2
set PDK_WORK   $env(HOME)/flash/ihp
set PDK_CFG    $env(HOME)/flash/pdk_cfg/ihp_sg13g2

# Libraries. The IHP antenna deck counts any contacted diffusion over 0.16 um2 on a net as a protection
# diode (antenna.drc: diode = nactiv_con.join(pactiv_con), has_diode = area > 0.16), so driver drains
# protect and the unmodified cell LEF is right.
set NDM_LIB    $PDK_WORK/ndm/sg13g2_stdcell.ndm
set DB_DIR     $PDK_WORK/db
set TLUP       $PDK_WORK/rc/sg13g2_typ.tluplus
set NXTGRD     $PDK_WORK/rc/sg13g2_typ.nxtgrd
set RC_MAP     $PDK_WORK/rc/tf_itf.map
set GDS_CELLS  $PDK_ROOT/libs.ref/sg13g2_stdcell/gds/sg13g2_stdcell.gds
set GDS_MAP    $PDK_CFG/gds_out.map

# Corners: name, VDD, temperature, Liberty (.db) name. Process label is 1 in every IHP library.
set CORNERS {
  slow 1.08 125 sg13g2_stdcell_slow_1p08V_125C
  typ  1.20  25 sg13g2_stdcell_typ_1p20V_25C
  fast 1.32 -40 sg13g2_stdcell_fast_1p32V_m40C
}
set POWER_CORNER typ

# Cells.
set DRIVE_CELL   sg13g2_buf_2
set DECAP_CELLS  {sg13g2_decap_8 sg13g2_decap_4}
set FILL_CELLS   {sg13g2_fill_8 sg13g2_fill_4 sg13g2_fill_2 sg13g2_fill_1}
set DIODE_CELL   sg13g2_antennanp
# IO ring cells (sg13g2_io): corner, and fillers from widest to narrowest (50, 20, 10, 5, 2, 1 um).
set IO_CORNER    sg13g2_Corner
# IO supply per corner, as the sg13g2_io libraries are characterized: 3.0 V slow, 3.3 V typ, 3.6 V fast.
set IO_VDD       {slow 3.0 typ 3.3 fast 3.6}
# Core supply rails in sg13g2_io cells, 140-158 and 160-178 um from the die edge: Metal4, Metal5 and TopMetal1
# put VSS nearer the core, Metal3 puts VDD nearer. Each net reaches the pads on a layer where its rail is the
# nearer one, starting at the rail's middle: {net vertical_layer horizontal_layer rail_offset pitch_offset}.
# VSS runs on Metal4 across the top and bottom and on Metal5 at the sides, so it never runs along the core
# ring's own layer on that side.
set IO_CORE_STRAPS {{VDD Metal3 Metal3 169 50} {VSS Metal4 Metal5 170 100}}
# IO supply pads: cell, supply net, pin. Their bond side is where the IO supply enters the chip.
set IO_SUPPLY_CELLS {sg13g2_IOPadIOVdd IOVDD iovdd sg13g2_IOPadIOVss IOVSS iovss}
# IO supply pins on every sg13g2_io cell, and the supply nets they belong to.
set IO_SUPPLY_PINS {iovdd IOVDD iovss IOVSS}
set IO_FILLERS   {sg13g2_Filler10000 sg13g2_Filler4000 sg13g2_Filler2000 sg13g2_Filler1000 sg13g2_Filler400 sg13g2_Filler200}

# Routing. Tracks: IHP librelane tracks.info.
set ROUTE_MIN_LAYER Metal2
# TopMetal1/2 carry power; signal routing tops out at Metal5.
set MAX_ROUTE_LAYER Metal5
set PIN_LAYERS      {Metal3 Metal4}

# Power grid. Rails: 0.44 um Metal1 (VDD/VSS pins in sg13g2_stdcell.lef).
set RAIL_LAYER   Metal1
set RAIL_W       0.44
set RING_H_LAYER Metal5
set RING_V_LAYER Metal4
set RING_SPACING 1.0
set MESH_V_LAYER Metal4
set MESH_H_LAYER Metal5
set MESH_V_W     1.0
set MESH_H_W     1.0
set MESH_PITCH   25.0
# Via arrays larger than 3x3 cuts: 0.29 um cut spacing (LEF SPACING 0.29 ADJACENTCUTS 3; DRC V1.b1..V4.b1).
# No tech-file field carries this, so the PG via masters do.
set PG_VIA_RULES {Via1_YX 0.29 Via2_YX 0.29 Via3_YX 0.29 Via4_YX 0.29}

# Wide-metal spacing (Mn.e/Mn.f): {min_width spacing} steps, applied as keepouts beside wide PG shapes,
# because FC's route check does not apply them between signal wires and PG stripes.
set WIDE_STEPS {Metal2 {0.39 0.24 10.0 0.60} Metal3 {0.39 0.24 10.0 0.60} Metal4 {0.39 0.24 10.0 0.60} Metal5 {0.39 0.24 10.0 0.60}}

# Antenna (layout rules 7.1, antenna.drc): cumulative area ratio 200 (metal) / 20 (via) without a diode,
# 20000 / 500 with one, where "diode" is any contacted diffusion over 0.16 um2 on the net. Mode 3 counts
# all lower-layer metal, like IHP's cumulative Ant.b. diode_ratio {v0 v1 v2 v3}: ratio = (protection + v1)
# * v2 + v3 when protection > v0. The nets IHP still flags on a block are input ports with no driver
# inside it; the flow buffers inputs at the pin for that.
set ANT_ENABLE      1
set ANT_MODE        3
set ANT_DIODE_MODE  2
set ANT_GLOBAL      {200 20}
set ANT_LAYER_RULES {}
foreach l {Metal1 Metal2 Metal3 Metal4 Metal5 TopMetal1 TopMetal2} { lappend ANT_LAYER_RULES $l 200 {0.16 0 0 20000} }
foreach l {Via1 Via2 Via3 Via4 TopVia1 TopVia2} { lappend ANT_LAYER_RULES $l 20 {0.16 0 0 500} }

# IHP cells carry their own substrate and well ties and expose no separate body pins.
set TAP_CELL  ""
set TAP_DIST  0
set EXTRA_PG  {}
# Delay cells and a small buffer for PrimeTime hold ECOs; see pt_signoff.tcl.
set ECO_HOLD_BUFFERS {sg13g2_dlygate4sd1_1 sg13g2_dlygate4sd2_1 sg13g2_dlygate4sd3_1 sg13g2_buf_1}
# Buffers PrimeTime may insert in a noise ECO to split a victim net; see pt_signoff.tcl.
set ECO_BUFFERS {sg13g2_buf_2 sg13g2_buf_4}
# SRAM halo, unless the run sets one: the standard-cell N-well overhangs the cell by 0.24 um and the SRAM N-well
# reaches its edge, so NW.b1, 1.80 um, needs about 2.04 um.
if {![info exists MACRO_HALO]} { set MACRO_HALO 2.5 }
