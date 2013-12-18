{ pow, ceil, log } = Math

exports.roundUpToNextPowerOf4 = (n) -> pow 4, (ceil (log n) / (log 4))
