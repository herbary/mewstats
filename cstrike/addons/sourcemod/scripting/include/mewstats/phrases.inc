// Mewstats
//
// Copyright (C) 2026  Mee;w
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

#if defined _mewstats_phrases_included_
#endinput
#endif
#define _mewstats_phrases_included_

#include <mewstats/info>

#define MEWSTATS_MESSAGE_FILENAME MEWSTATS_NAME_LOWER ... ".phrases"
#define MEWSTATS_MESSAGE_IMPL(%1) MEWSTATS_NAME ... " / " ... %1
#define MEWSTATS_MESSAGE_KEY_SIZE 128

#define MEWSTATS_MESSAGE_THROW_SPEED MEWSTATS_MESSAGE_IMPL("Throw Speed")
#define MEWSTATS_MESSAGE_SHORT_THROW_SPEED MEWSTATS_MESSAGE_IMPL("Short Throw Speed")
#define MEWSTATS_MESSAGE_DUCK_THROW_SPEED MEWSTATS_MESSAGE_IMPL("Duck Throw Speed")
#define MEWSTATS_MESSAGE_SHORT_DUCK_THROW_SPEED MEWSTATS_MESSAGE_IMPL("Short Duck Throw Speed")
#define MEWSTATS_MESSAGE_CROUCH_THROW_SPEED MEWSTATS_MESSAGE_IMPL("Crouch Throw Speed")
#define MEWSTATS_MESSAGE_SHORT_CROUCH_THROW_SPEED MEWSTATS_MESSAGE_IMPL("Short Crouch Throw Speed")
#define MEWSTATS_MESSAGE_THROW_ANGLE MEWSTATS_MESSAGE_IMPL("Throw Angle")
#define MEWSTATS_MESSAGE_SHORT_THROW_ANGLE MEWSTATS_MESSAGE_IMPL("Short Throw Angle")
#define MEWSTATS_MESSAGE_THROW_TIME MEWSTATS_MESSAGE_IMPL("Throw Time")
#define MEWSTATS_MESSAGE_SHORT_THROW_TIME MEWSTATS_MESSAGE_IMPL("Short Throw Time")
#define MEWSTATS_MESSAGE_THROW_DEVIATION MEWSTATS_MESSAGE_IMPL("Throw Deviation")
#define MEWSTATS_MESSAGE_SHORT_THROW_DEVIATION MEWSTATS_MESSAGE_IMPL("Short Throw Deviation")
#define MEWSTATS_MESSAGE_NOJUMP_STATUS MEWSTATS_MESSAGE_IMPL("NoJump Status")
#define MEWSTATS_MESSAGE_SHORT_NOJUMP_STATUS MEWSTATS_MESSAGE_IMPL("Short NoJump Status")
#define MEWSTATS_MESSAGE_SKY_JUMP MEWSTATS_MESSAGE_IMPL("Sky Jump")
