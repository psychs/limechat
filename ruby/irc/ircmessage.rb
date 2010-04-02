# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

module IRC
  MSG_LEN = 510
  BODY_LEN = 500
  ADDRESS_LEN = 50
end

module Penalty
  NORMAL = 2
  PART = 4
  KICK_BASE = 1
  KICK_OPT = 3
  MODE_BASE = 1
  MODE_OPT = 3
  TOPIC = 3
  INIT = 0
  MAX = 10
  TEXT_SIZE_FACTOR = 120
end
