fs = require 'fs'
Structure = require './structure'
{ SIZEOF } = require './const'

module.exports = class WRP extends Structure
  constructor: (src) ->
    super (fs.readFileSync src), 'LE'

  Header: =>
    type: @char 4
    version: @uint32()
    layerSize: @XYPair()
    mapSize: @XYPair()
    layerCellSize: @float()

  ClassedModel: =>
    className: @Asciiz()
    modelPath: @Asciiz()
    position: @XYZTriplet()
    unknown: @uint32()

  RoadNet: =>
    nRoadParts = @uint32()
    (@RoadPart() for i in [0...nRoadParts])

  RoadPart: =>
    nRoadPositions = @uint16()
    roadPositions: (@XYZTriplet() for i in [0...nRoadPositions])
    flags1: [@byte(), @byte(), @byte(), @byte()]
    flags2: (@byte() for i in [0...nRoadPositions])
    p3dModel: @Asciiz()
    transform: @TransformMatrix()

  Object: =>
    id: @uint32()
    model: @uint32()
    transform: @TransformMatrix()
    unknown: @uint32()

  MapInfo: =>
    type = @uint32()
    switch type
      when 0, 1, 2, 10, 11, 13, 14, 15, 16, 17, 22, 23, 26, 27, 30 then @MapType1()
      when 24, 31, 32 then @MapType2()
      when 25, 33 then @MapType3()
      when 3, 4, 8, 9, 18, 19, 20, 21, 28, 29 then @MapType4()
      when 34 then @MapType5()
      when 35 then @MapType35()
      else throw new Error 'unknown MapType'

  MapType1: =>
    id: @uint32()
    x: @float()
    z: @float()
    type: 1

  MapType2: =>
    id: @uint32()
    bounds: ([@float(), @float()] for i in [0...4])
    type: 2

  MapType3: =>
    color: @RGBAColor()
    indicator: @uint32()
    unknowns: [@float(), @float(), @float(), @float()]
    type: 3

  MapType4: =>
    id: @uint32()
    bounds: ([@float(), @float()] for i in [0...4])
    color: @RGBAColor()
    type: 4

  MapType5: =>
    id: @uint32()
    line: ([@float(), @float()] for i in [0...2])
    type: 5

  MapType35: =>
    id: @uint32()
    line: ([@float(), @float()] for i in [0...3])
    unknown: @byte()
    type: 35

  parse: =>
    output = o = {}

    o.header = @Header()

    o.env = @GridBlock o.header.mapSize, SIZEOF.UINT16

    o.envSounds = @GridBlock o.header.mapSize, SIZEOF.BYTE

    nPeaks = @uint32()
    o.peaks = (@XYZTriplet() for i in [0...nPeaks])

    o.rvmatLayerIndex = @GridBlock o.header.layerSize, SIZEOF.UINT16

    o.randomClutter = @LZOCompressed o.header.mapSize[0] * o.header.mapSize[1]

    o.compressedBytes1 = @LZOCompressed o.header.mapSize[0] * o.header.mapSize[1]

    o.elevation = @LZOCompressed o.header.mapSize[0] * o.header.mapSize[1] * SIZEOF.FLOAT

    nRvmats = @uint32()
    o.rvmats = (@Filenames() for i in [0...nRvmats])

    nModels = @uint32()
    o.modelPaths = (@Asciiz() for i in [0...nModels])

    nClassedModels = @uint32()
    o.models = (@ClassedModel() for i in [0...nClassedModels])

    o.unknownGrid1 = @GridBlock o.header.mapSize, SIZEOF.BYTE

    sizeOfObjects = @uint32()

    o.unknownGrid2 = @GridBlock o.header.mapSize, SIZEOF.BYTE

    sizeOfMapInfo = @uint32()

    o.compressedBytes2 = @LZOCompressed o.header.layerSize[0] * o.header.layerSize[1]
    o.compressedBytes3 = @LZOCompressed o.header.mapSize[0] * o.header.mapSize[1]

    maxObjectId = @uint32()

    sizeOfRoadNets = @uint32()
    o.roadNets = (@RoadNet() for i in [0...o.header.layerSize[0] * o.header.layerSize[1]])

    o.objects = (@Object() for i in [0...sizeOfObjects/SIZEOF.OBJECT])

    o.mapInfos = (@MapInfo() while @offset isnt @buffer.length)

    return o
