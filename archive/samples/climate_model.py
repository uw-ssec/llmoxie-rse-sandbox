import math

def estimate_temperature(day_of_year: int) -> float:
    """
    Very simple seasonal toy model.
    Try asking Copilot or an RSE plugin to:
    - explain the model
    - refactor it
    - add tests
    - make the assumptions clearer
    """
    return 15 + 10 * math.sin((2 * math.pi * day_of_year) / 365)

if __name__ == "__main__":
    for day in [1, 90, 180, 270]:
        print(f"Day {day}: {estimate_temperature(day):.2f} °C")
