#!/usr/bin/env python

import sys
import ROOT


def main():
    f = ROOT.TFile("energy.root")
    h = f.Get("energy")

    val = h.GetBinContent(1)
    err = h.GetBinError(1)

    print(f"{val} ± {err}")

    # uncomment to draw the histogram:
    # h.Draw("hist e")
    # input()


if __name__ == "__main__":
    sys.exit(main())
