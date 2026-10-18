# AI acknowledgement: this plotting script was generated with the help of
# Claude (Anthropic) and reviewed/adapted by me. The data extraction from
# the CSV is done in Bash (server.sh); Python is used only for plotting.

import sys
import matplotlib
matplotlib.use("Agg")  # headless backend: no display needed in the container
import matplotlib.pyplot as plt


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 plot_population.py <plot.csv> [output_png]", file=sys.stderr)
        sys.exit(1)

    in_file = sys.argv[1]
    out_file = sys.argv[2] if len(sys.argv) > 2 else "population.png"

    try:
        with open(in_file) as f:
            lines = [l.strip() for l in f if l.strip()]
        years = [int(x) for x in lines[0].split(",")]
        pops = [int(x) for x in lines[1].split(",")]
    except (OSError, IndexError, ValueError) as e:
        print(f"Error: could not read population data ({e})", file=sys.stderr)
        sys.exit(1)

    if len(years) != len(pops):
        print("Error: years and populations have different lengths", file=sys.stderr)
        sys.exit(1)

    plt.figure(figsize=(8, 5))
    plt.plot(years, pops, marker="o")
    plt.xlabel("Year")
    plt.ylabel("Population")
    plt.title("NSW Estimated Resident Population")
    plt.xticks(years)                              # one tick per year, no 2020.5
    plt.ticklabel_format(style="plain", axis="y")  # avoid 1e6 notation
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(out_file)


if __name__ == "__main__":
    main()