fs = require 'fs'
Structure = require './structure'
{ SIZEOF } = require './const'

module.exports = class WRP extends Structure
  constructor: (src) ->
    super (fs.readFileSync src), 'LE'

  Header: =>
    filename: @Asciiz()
    packingMethod: @uint32()
    originalSize: @uint32()
    reserved: @uint32()
    timestamp: @uint32()
    dataSize: @uint32()

  HeaderExtension: =>
    extension = []
    asciiz = @Asciiz()
    while asciiz isnt ''
      extension.push asciiz
      asciiz = @Asciiz()
    return extension

  parse: =>
    output = o = {}

    o.header = @Header()
    o.headerExtension = @HeaderExtension()

    o.entries = []
    entry = @Header()
    while entry.filename isnt ''
      o.entries.push entry
      entry = @Header()

    for entry in o.entries
      entry.data = @read entry.dataSize

    o.checksum = @read 21

    return o
