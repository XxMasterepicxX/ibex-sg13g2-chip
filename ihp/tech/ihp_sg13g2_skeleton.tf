/* IHP SG13G2 layer skeleton for Fusion Compiler.
   Layer names and GDS numbers: ihp-sg13g2/libs.tech/klayout/tech/sg13g2.map and sg13g2.lyp.
   Widths, spacings, areas and pitches: ihp-sg13g2/libs.ref/sg13g2_stdcell/lef/sg13g2_tech.lef.
   Spacing tables are the LEF SPACINGTABLE PARALLELRUNLENGTH values: rows are wire width, columns are parallel run length.
   Vias are read from the same tech LEF by read_lef. */

Technology {
    name                    = "sg13g2"
    unitTimeName            = "ns"
    timePrecision           = 1000
    unitLengthName          = "micron"
    lengthPrecision         = 1000
    gridResolution          = 5
    unitVoltageName         = "V"
    voltagePrecision        = 1000000
    unitCurrentName         = "mA"
    currentPrecision        = 1000
    unitPowerName           = "mW"
    powerPrecision          = 1000
    unitResistanceName      = "kohm"
    resistancePrecision     = 10000000
    unitCapacitanceName     = "pf"
    capacitancePrecision    = 10000000
    unitInductanceName      = "nh"
    inductancePrecision     = 100
}

Layer "GatPoly" {
    layerNumber             = 5
    maskName                = "poly"
    isDefaultLayer          = 1
}

Layer "Cont" {
    layerNumber             = 6
    maskName                = "polyCont"
    isDefaultLayer          = 1
    minWidth                = 0.16
    minSpacing              = 0.18
}

Layer "Metal1" {
    layerNumber             = 8
    maskName                = "metal1"
    isDefaultLayer          = 1
    pitch                   = 0.42
    defaultWidth            = 0.16
    minWidth                = 0.16
    maxWidth                = 30
    minSpacing              = 0.18
    minArea                 = 0.09
    fatTblDimension         = 3
    fatTblThreshold         = (0, 0.3, 10.0)
    fatTblParallelLength    = (0, 1.0, 10.0)
    fatTblSpacing           = (0.18, 0.18, 0.18,
                              0.18, 0.22, 0.22,
                              0.18, 0.22, 0.6)
}

Layer "Via1" {
    layerNumber             = 19
    maskName                = "via1"
    isDefaultLayer          = 1
    minWidth                = 0.19
    minSpacing              = 0.22
}

Layer "Metal2" {
    layerNumber             = 10
    maskName                = "metal2"
    isDefaultLayer          = 1
    pitch                   = 0.48
    defaultWidth            = 0.20
    minWidth                = 0.20
    maxWidth                = 30
    minSpacing              = 0.21
    minArea                 = 0.144
    fatTblDimension         = 3
    fatTblThreshold         = (0, 0.39, 10.0)
    fatTblParallelLength    = (0, 1.0, 10.0)
    fatTblSpacing           = (0.21, 0.21, 0.21,
                              0.21, 0.24, 0.24,
                              0.21, 0.24, 0.6)
}

Layer "Via2" {
    layerNumber             = 29
    maskName                = "via2"
    isDefaultLayer          = 1
    minWidth                = 0.19
    minSpacing              = 0.22
}

Layer "Metal3" {
    layerNumber             = 30
    maskName                = "metal3"
    isDefaultLayer          = 1
    pitch                   = 0.42
    defaultWidth            = 0.20
    minWidth                = 0.20
    minSpacing              = 0.21
    minArea                 = 0.144
    fatTblDimension         = 3
    fatTblThreshold         = (0, 0.39, 10.0)
    fatTblParallelLength    = (0, 1.0, 10.0)
    fatTblSpacing           = (0.21, 0.21, 0.21,
                              0.21, 0.24, 0.24,
                              0.21, 0.24, 0.6)
}

Layer "Via3" {
    layerNumber             = 49
    maskName                = "via3"
    isDefaultLayer          = 1
    minWidth                = 0.19
    minSpacing              = 0.22
}

Layer "Metal4" {
    layerNumber             = 50
    maskName                = "metal4"
    isDefaultLayer          = 1
    pitch                   = 0.48
    defaultWidth            = 0.20
    minWidth                = 0.20
    minSpacing              = 0.21
    minArea                 = 0.144
    fatTblDimension         = 3
    fatTblThreshold         = (0, 0.39, 10.0)
    fatTblParallelLength    = (0, 1.0, 10.0)
    fatTblSpacing           = (0.21, 0.21, 0.21,
                              0.21, 0.24, 0.24,
                              0.21, 0.24, 0.6)
}

Layer "Via4" {
    layerNumber             = 66
    maskName                = "via4"
    isDefaultLayer          = 1
    minWidth                = 0.19
    minSpacing              = 0.22
}

Layer "Metal5" {
    layerNumber             = 67
    maskName                = "metal5"
    isDefaultLayer          = 1
    pitch                   = 0.42
    defaultWidth            = 0.20
    minWidth                = 0.20
    minSpacing              = 0.21
    minArea                 = 0.144
    fatTblDimension         = 3
    fatTblThreshold         = (0, 0.39, 10.0)
    fatTblParallelLength    = (0, 1.0, 10.0)
    fatTblSpacing           = (0.21, 0.21, 0.21,
                              0.21, 0.24, 0.24,
                              0.21, 0.24, 0.6)
}

Layer "TopVia1" {
    layerNumber             = 125
    maskName                = "via5"
    isDefaultLayer          = 1
    minWidth                = 0.42
    minSpacing              = 0.42
}

Layer "TopMetal1" {
    layerNumber             = 126
    maskName                = "metal6"
    isDefaultLayer          = 1
    pitch                   = 3.28
    defaultWidth            = 1.64
    minWidth                = 1.64
    minSpacing              = 1.64
}

Layer "TopVia2" {
    layerNumber             = 133
    maskName                = "via6"
    isDefaultLayer          = 1
    minWidth                = 0.9
    minSpacing              = 1.06
}

Layer "TopMetal2" {
    layerNumber             = 134
    maskName                = "metal7"
    isDefaultLayer          = 1
    pitch                   = 4.0
    defaultWidth            = 2.0
    minWidth                = 2.0
    minSpacing              = 2.0
    fatTblDimension         = 2
    fatTblThreshold         = (0, 5.0)
    fatTblParallelLength    = (0, 50.0)
    fatTblSpacing           = (2.0, 2.0,
                              2.0, 5.0)
}

/* Default vias from the tech LEF: Via1_YX to Via4_YX, TopVia1EWNS, TopVia2EWNS.
   Enclosure = half of (metal rectangle size - cut size), per axis. */

ContactCode "Via1_YX" {
    contactCodeNumber       = 1
    cutLayer                = "Via1"
    lowerLayer              = "Metal1"
    upperLayer              = "Metal2"
    cutWidth                = 0.19
    cutHeight               = 0.19
    lowerLayerEncWidth      = 0.01
    lowerLayerEncHeight     = 0.05
    upperLayerEncWidth      = 0.05
    upperLayerEncHeight     = 0.005
    minCutSpacing           = 0.22
    isDefaultContact        = 1
}

ContactCode "Via2_YX" {
    contactCodeNumber       = 2
    cutLayer                = "Via2"
    lowerLayer              = "Metal2"
    upperLayer              = "Metal3"
    cutWidth                = 0.19
    cutHeight               = 0.19
    lowerLayerEncWidth      = 0.01
    lowerLayerEncHeight     = 0.05
    upperLayerEncWidth      = 0.05
    upperLayerEncHeight     = 0.005
    minCutSpacing           = 0.22
    isDefaultContact        = 1
}

ContactCode "Via3_YX" {
    contactCodeNumber       = 3
    cutLayer                = "Via3"
    lowerLayer              = "Metal3"
    upperLayer              = "Metal4"
    cutWidth                = 0.19
    cutHeight               = 0.19
    lowerLayerEncWidth      = 0.01
    lowerLayerEncHeight     = 0.05
    upperLayerEncWidth      = 0.05
    upperLayerEncHeight     = 0.005
    minCutSpacing           = 0.22
    isDefaultContact        = 1
}

ContactCode "Via4_YX" {
    contactCodeNumber       = 4
    cutLayer                = "Via4"
    lowerLayer              = "Metal4"
    upperLayer              = "Metal5"
    cutWidth                = 0.19
    cutHeight               = 0.19
    lowerLayerEncWidth      = 0.01
    lowerLayerEncHeight     = 0.05
    upperLayerEncWidth      = 0.05
    upperLayerEncHeight     = 0.005
    minCutSpacing           = 0.22
    isDefaultContact        = 1
}

ContactCode "TopVia1EWNS" {
    contactCodeNumber       = 5
    cutLayer                = "TopVia1"
    lowerLayer              = "Metal5"
    upperLayer              = "TopMetal1"
    cutWidth                = 0.42
    cutHeight               = 0.42
    lowerLayerEncWidth      = 0.1
    lowerLayerEncHeight     = 0.1
    upperLayerEncWidth      = 0.54
    upperLayerEncHeight     = 0.54
    minCutSpacing           = 0.42
    isDefaultContact        = 1
}

ContactCode "TopVia2EWNS" {
    contactCodeNumber       = 6
    cutLayer                = "TopVia2"
    lowerLayer              = "TopMetal1"
    upperLayer              = "TopMetal2"
    cutWidth                = 0.9
    cutHeight               = 0.9
    lowerLayerEncWidth      = 0.5
    lowerLayerEncHeight     = 0.5
    upperLayerEncWidth      = 0.5
    upperLayerEncHeight     = 0.5
    minCutSpacing           = 1.06
    isDefaultContact        = 1
}
