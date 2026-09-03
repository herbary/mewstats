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
