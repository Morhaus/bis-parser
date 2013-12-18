{ spawn } = require 'child_process'
lzo = require 'mini-lzo-wrapper'
Consumable = require './consumable'
{ SIZEOF } = require './const'
{ roundUpToNextPowerOf4 } = require './util'

module.exports = class Structure extends Consumable
  String: =>
    length = @uint32()
    if length > 1
      (@char length)[...-1]
    else
      @move 1
      ''

  Asciiz: =>
    asciiz = ''
    char = @char()
    while char isnt '\x00'
      asciiz += char
      char = @char()
    return asciiz

  RGBAColor: => [@byte(), @byte(), @byte(), @byte()]

  XYPair: => [@uint32(), @uint32()]

  XYZTriplet: => [@float(), @float(), @float()]

  TransformMatrix: => ((@float() for i in [0...4]) for j in [0...3])

  GridBlock: (size, typeSize) =>
    present = @byte()
    if not present
      @move 4
      []
    else
      buffer = new Buffer (size[0] * size[1] * typeSize)
      buffer.fill 0

      initialGridSize = roundUpToNextPowerOf4 (Math.max size[0], size[1]) * (typeSize / SIZEOF.UINT16)
      do readGrid = (gridSize = initialGridSize, gridOffset = [0, 0]) =>
        flag = @uint16()
        # We divide the grid in 16 blocks of equal size.
        blockSize = gridSize / 4

        for i in [0...16]
          # We calculate the offset of the block.
          blockOffset = [
            gridOffset[0] + (i % 4) * blockSize
            gridOffset[1] + (Math.floor i / 4) * blockSize
          ]

          if flag & 1
            flag >>= 1
            # The block is a grid.
            readGrid blockSize, blockOffset
          else
            flag >>= 1
            # The block is uniformly filled.
            [a, b] = [@uint16(), @uint16()]

            continue if a is b is 0 # The output buffer is already filled with zeroes.

            for y in [blockOffset[1]...blockOffset[1] + blockSize]
              for x in [blockOffset[0]...blockOffset[0] + blockSize]
                offsetA = (y * size[0] + x)
                offsetB = offsetA + blockSize
                buffer.writeUInt16LE a, offsetA * SIZEOF.UINT16
                buffer.writeUInt16LE b, offsetB * SIZEOF.UINT16

      return buffer

  LZOCompressed: (outputSize) =>
    input = @buffer[@offset...@offset + outputSize * 2]
    output = new Buffer outputSize

    [inputLen, outputLen] = lzo.decompress input, output
    @offset += inputLen
    return output

  Filenames: =>
    filenames = []
    filename = @Asciiz()
    if filename is ''
      @move 1
      return filenames
    while filename isnt ''
      filenames.push filename
      filename = @Asciiz()
    return filenames
