fs = require 'fs'

module.exports = class Consumable
  @fromFile: (src, endian) ->
    raw = fs.readFileSync src
    new Consumable raw, endian

  constructor: (@buffer, @endian = 'BE') ->
    @offset = 0
    @_bigEndian = @endian is 'BE'

  read: (n) ->
    @offset += n
    @buffer[@offset - n...@offset]

  move: (n) ->
    @offset += n

  byte: ->
    value = @buffer[@offset]
    @offset += 1
    value

  int8: ->
    value = @buffer.readInt8 @offset
    @offset += 1
    value
  uint8: ->
    value = @buffer.readUInt8 @offset
    @offset += 1
    value

  int16: ->
    value = if @_bigEndian then (@buffer.readInt16BE @offset) else (@buffer.readInt16LE @offset)
    @offset += 2
    value
  uint16: ->
    value = if @_bigEndian then (@buffer.readUInt16BE @offset) else (@buffer.readUInt16LE @offset)
    @offset += 2
    value

  int32: ->
    value = if @_bigEndian then (@buffer.readInt32BE @offset) else (@buffer.readInt32LE @offset)
    @offset += 4
    value
  uint32: ->
    value = if @_bigEndian then (@buffer.readUInt32BE @offset) else (@buffer.readUInt32LE @offset)
    @offset += 4
    value

  float: ->
    value = if @_bigEndian then (@buffer.readFloatBE @offset) else (@buffer.readFloatLE @offset)
    @offset += 4
    value

  double: ->
    value = if @_bigEndian then (@buffer.readDoubleBE @offset) else (@buffer.readDoubleLE @offset)
    @offset += 8
    value

  char: (n = 1) =>
    (@read n).toString 'ascii'
