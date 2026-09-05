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

#if defined _mewstats_color_included_
#endinput
#endif
#define _mewstats_color_included_

stock void Mewstats_TransColor(float percent, float midpoint, int color[3])
{
    if (percent < 0.0)
    {
        percent = 0.0;
    }
    if (percent > 100.0)
    {
        percent = 100.0;
    }

    int base = 0;
    int range = 255 - base;

    int red, green;
    if (percent < midpoint)
    {
        red = 255;
        green = base + RoundToNearest((percent / midpoint) * range);
    }
    else
    {
        green = 255;
        red = base + RoundToNearest(((100.0 - percent) / (100.0 - midpoint)) * range);
    }

    if (red < 0)
    {
        red = 0;
    }
    if (red > 255)
    {
        red = 255;
    }

    if (green < 0)
    {
        green = 0;
    }
    if (green > 255)
    {
        green = 255;
    }

    color[0] = red;
    color[1] = green;
    color[2] = base;
}
