import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("samples/climate_data.csv")

plt.plot(df["day"], df["temperature_c"])
plt.title("Temperature over time")
plt.xlabel("Day")
plt.ylabel("Temperature (°C)")
plt.tight_layout()
plt.show()

# Try asking Copilot or an RSE plugin to:
# - improve this plot
# - add a moving average
# - split the script into reusable functions
