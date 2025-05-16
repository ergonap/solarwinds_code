# Gex-TOS

# Gamma Exposure (GEX) Monitor - 10 closest strikes, 5-min update

input min_gex = 50;
input strikes = 10;
input agg = AggregationPeriod.FIVE_MIN;
input Expiration_YYMMDD = 20250117; # Set to your desired expiration

def S = close;
def DateString = Expiration_YYMMDD;
def Sqrt_pi = Sqrt(2 * Double.Pi);

# Find nearest strike (rounded to nearest 5)
def base_strike = Round(S / 5, 0) * 5;

# Generate strike prices
def strike = base_strike + (GetValue(-strikes, 0, 1) * 5);
def strikeArr = fold i = -strikes to strikes + 1 with arr do arr + (base_strike + i * 5);

# Calculate gamma for each strike (Black-Scholes approximation)
def IV = imp_volatility();
def t = (DaysTillExpiration(DateString) / 365);
def Sqr_IV_2 = Sqr(IV) / 2;
def Sqrt_t_iv = Sqrt(t) * IV;
def Sqrt_t_iv_S = Sqrt_t_iv * S;
def gamma(i) = (Exp(-(Sqr((Log(S / (base_strike + i * 5)) + Sqr_IV_2) / Sqrt_t_iv) / 2)) / Sqrt_pi) / Sqrt_t_iv_S;

# Open Interest for calls and puts
def call_oi(i) = if IsNaN(open_interest("." + GetSymbol() + AsPrice(DateString) + "C" + AsPrice(base_strike + i * 5), period=agg)) then 0 else open_interest("." + GetSymbol() + AsPrice(DateString) + "C" + AsPrice(base_strike + i * 5), period=agg);
def put_oi(i)  = if IsNaN(open_interest("." + GetSymbol() + AsPrice(DateString) + "P" + AsPrice(base_strike + i * 5), period=agg)) then 0 else open_interest("." + GetSymbol() + AsPrice(DateString) + "P" + AsPrice(base_strike + i * 5), period=agg);

# GEX calculation for each strike
def gex(i) = Round(gamma(i) * (call_oi(i) - put_oi(i)) * S / 10000, 0);

# Plot horizontal bars for each strike
plot GEX_Bar;
GEX_Bar = Double.NaN;
GEX_Bar.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
GEX_Bar.SetLineWeight(5);

# Loop for plotting
script plotGEX {
    input idx = 0;
    def gexVal = gex(idx);
    plot bar = if AbsValue(gexVal) > min_gex then gexVal else Double.NaN;
    bar.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
    bar.AssignValueColor(if gexVal > 0 then Color.GREEN else Color.RED);
    bar.SetLineWeight(5);
}
# Plot for each strike
plotGEX(-10);
plotGEX(-9);
plotGEX(-8);
plotGEX(-7);
plotGEX(-6);
plotGEX(-5);
plotGEX(-4);
plotGEX(-3);
plotGEX(-2);
plotGEX(-1);
plotGEX(0);
plotGEX(1);
plotGEX(2);
plotGEX(3);
plotGEX(4);
plotGEX(5);
plotGEX(6);
plotGEX(7);
plotGEX(8);
plotGEX(9);
plotGEX(10);

# Optional: Add labels for each strike
AddLabel(yes, "GEX (10 closest strikes) - Exp: " + Expiration_YYMMDD, Color.YELLOW);
