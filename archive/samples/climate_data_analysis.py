import pandas as pd

df = pd.read_csv("samples/climate_data.csv")

# Try asking Copilot or an RSE plugin to:
# - summarize this dataset
# - compute monthly averages
# - identify anomalies
# - suggest a cleaner analysis structure

print(df.head())
print(df.describe())
