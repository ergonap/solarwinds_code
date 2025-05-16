# Gamma Exposure (GEX) Monitor - 10 closest strikes, 5-min update

input min_gex = 50;
input agg = AggregationPeriod.FIVE_MIN;
input Expiration_YYMMDD = 20250117; # Set to your desired expiration

def S = close;
def DateString = Expiration_YYMMDD;
def Sqrt_pi = Sqrt(2 * Double.Pi);

# Find nearest strike (rounded to nearest 5)
def base_strike = Round(S / 5, 0) * 5;

def IV = imp_volatility();
def t = (DaysTillExpiration(DateString) / 365);
def Sqr_IV_2 = Sqr(IV) / 2;
def Sqrt_t_iv = Sqrt(t) * IV;
def Sqrt_t_iv_S = Sqrt_t_iv * S;

# Helper macro for gamma calculation
script calcGamma {
    input strike = 0.0;
    input S = 0.0;
    input Sqr_IV_2 = 0.0;
    input Sqrt_t_iv = 0.0;
    input Sqrt_pi = 0.0;
    input Sqrt_t_iv_S = 0.0;
    plot gamma = (Exp(-(Sqr((Log(S / strike) + Sqr_IV_2) / Sqrt_t_iv) / 2)) / Sqrt_pi) / Sqrt_t_iv_S;
}

# Helper macro for OI
script getOI {
    input strike = 0.0;
    input DateString = 0;
    input agg = 0;
    input type = "C";
    def sym = "." + GetSymbol() + AsPrice(DateString) + type + AsPrice(strike);
    plot oi = if IsNaN(open_interest(sym, period=agg)) then 0 else open_interest(sym, period=agg);
}

# Calculate for each strike offset
def strike_m10 = base_strike - 50;
def strike_m9  = base_strike - 45;
def strike_m8  = base_strike - 40;
def strike_m7  = base_strike - 35;
def strike_m6  = base_strike - 30;
def strike_m5  = base_strike - 25;
def strike_m4  = base_strike - 20;
def strike_m3  = base_strike - 15;
def strike_m2  = base_strike - 10;
def strike_m1  = base_strike - 5;
def strike_0   = base_strike;
def strike_p1  = base_strike + 5;
def strike_p2  = base_strike + 10;
def strike_p3  = base_strike + 15;
def strike_p4  = base_strike + 20;
def strike_p5  = base_strike + 25;
def strike_p6  = base_strike + 30;
def strike_p7  = base_strike + 35;
def strike_p8  = base_strike + 40;
def strike_p9  = base_strike + 45;
def strike_p10 = base_strike + 50;

# Gamma
def gamma_m10 = calcGamma(strike_m10, S, Sqr_IV_2, Sqrt_t_iv, Sqrt_pi, Sqrt_t_iv_S);
def gamma_m9  = calcGamma(strike_m9,  S, Sqr_IV_2, Sqrt_t_iv, Sqrt_pi, Sqrt_t_iv_S);
def gamma_m8  = calcGamma(strike_m8,  S, Sqr_IV_2, Sqrt_t_iv, Sqrt_pi, Sqrt_t_iv_S);
def gamma_m7  = calcGamma(strike_m7,  S, Sqr_IV_2, Sqrt_t_iv, Sqrt_pi, Sqrt_t_iv_S);
def gamma_m6  = calcGamma(strike_m6,  S, Sqr_IV_2, Sqrt_t_iv, Sqrt_pi, Sqrt_t_iv_S);
def gamma_m5  = calcGamma(strike_m5,  S, Sqr_IV_2, Sqrt_t_iv, Sqrt_pi, Sqrt_t_iv_S);
def gamma_m4  = calcGamma(strike_m4,  S, Sqr_IV_2, Sqrt_t_iv, Sqrt_pi, Sqrt_t_iv_S);
def gamma_m3  = calcGamma(strike_m3,  S, Sqr_IV_2, Sqrt_t_iv, Sqrt_pi, Sqrt_t_iv_S);
def gamma_m2  = calcGamma(strike_m2,  S, Sqr_IV_2, Sqrt_t_iv, Sqrt_pi, Sqrt_t_iv_S);
def gamma_m1  = calcGamma(strike_m1,  S, Sqr_IV_2, Sqrt_t_iv, Sqrt_pi, Sqrt_t_iv_S);
def gamma_0   = calcGamma(strike_0,   S, Sqr_IV_2, Sqrt_t_iv, Sqrt_pi, Sqrt_t_iv_S);
def gamma_p1  = calcGamma(strike_p1,  S, Sqr_IV_2, Sqrt_t_iv, Sqrt_pi, Sqrt_t_iv_S);
def gamma_p2  = calcGamma(strike_p2,  S, Sqr_IV_2, Sqrt_t_iv, Sqrt_pi, Sqrt_t_iv_S);
def gamma_p3  = calcGamma(strike_p3,  S, Sqr_IV_2, Sqrt_t_iv, Sqrt_pi, Sqrt_t_iv_S);
def gamma_p4  = calcGamma(strike_p4,  S, Sqr_IV_2, Sqrt_t_iv, Sqrt_pi, Sqrt_t_iv_S);
def gamma_p5  = calcGamma(strike_p5,  S, Sqr_IV_2, Sqrt_t_iv, Sqrt_pi, Sqrt_t_iv_S);
def gamma_p6  = calcGamma(strike_p6,  S, Sqr_IV_2, Sqrt_t_iv, Sqrt_pi, Sqrt_t_iv_S);
def gamma_p7  = calcGamma(strike_p7,  S, Sqr_IV_2, Sqrt_t_iv, Sqrt_pi, Sqrt_t_iv_S);
def gamma_p8  = calcGamma(strike_p8,  S, Sqr_IV_2, Sqrt_t_iv, Sqrt_pi, Sqrt_t_iv_S);
def gamma_p9  = calcGamma(strike_p9,  S, Sqr_IV_2, Sqrt_t_iv, Sqrt_pi, Sqrt_t_iv_S);
def gamma_p10 = calcGamma(strike_p10, S, Sqr_IV_2, Sqrt_t_iv, Sqrt_pi, Sqrt_t_iv_S);

# OI
def call_oi_m10 = getOI(strike_m10, DateString, agg, "C");
def call_oi_m9  = getOI(strike_m9,  DateString, agg, "C");
def call_oi_m8  = getOI(strike_m8,  DateString, agg, "C");
def call_oi_m7  = getOI(strike_m7,  DateString, agg, "C");
def call_oi_m6  = getOI(strike_m6,  DateString, agg, "C");
def call_oi_m5  = getOI(strike_m5,  DateString, agg, "C");
def call_oi_m4  = getOI(strike_m4,  DateString, agg, "C");
def call_oi_m3  = getOI(strike_m3,  DateString, agg, "C");
def call_oi_m2  = getOI(strike_m2,  DateString, agg, "C");
def call_oi_m1  = getOI(strike_m1,  DateString, agg, "C");
def call_oi_0   = getOI(strike_0,   DateString, agg, "C");
def call_oi_p1  = getOI(strike_p1,  DateString, agg, "C");
def call_oi_p2  = getOI(strike_p2,  DateString, agg, "C");
def call_oi_p3  = getOI(strike_p3,  DateString, agg, "C");
def call_oi_p4  = getOI(strike_p4,  DateString, agg, "C");
def call_oi_p5  = getOI(strike_p5,  DateString, agg, "C");
def call_oi_p6  = getOI(strike_p6,  DateString, agg, "C");
def call_oi_p7  = getOI(strike_p7,  DateString, agg, "C");
def call_oi_p8  = getOI(strike_p8,  DateString, agg, "C");
def call_oi_p9  = getOI(strike_p9,  DateString, agg, "C");
def call_oi_p10 = getOI(strike_p10, DateString, agg, "C");

def put_oi_m10 = getOI(strike_m10, DateString, agg, "P");
def put_oi_m9  = getOI(strike_m9,  DateString, agg, "P");
def put_oi_m8  = getOI(strike_m8,  DateString, agg, "P");
def put_oi_m7  = getOI(strike_m7,  DateString, agg, "P");
def put_oi_m6  = getOI(strike_m6,  DateString, agg, "P");
def put_oi_m5  = getOI(strike_m5,  DateString, agg, "P");
def put_oi_m4  = getOI(strike_m4,  DateString, agg, "P");
def put_oi_m3  = getOI(strike_m3,  DateString, agg, "P");
def put_oi_m2  = getOI(strike_m2,  DateString, agg, "P");
def put_oi_m1  = getOI(strike_m1,  DateString, agg, "P");
def put_oi_0   = getOI(strike_0,   DateString, agg, "P");
def put_oi_p1  = getOI(strike_p1,  DateString, agg, "P");
def put_oi_p2  = getOI(strike_p2,  DateString, agg, "P");
def put_oi_p3  = getOI(strike_p3,  DateString, agg, "P");
def put_oi_p4  = getOI(strike_p4,  DateString, agg, "P");
def put_oi_p5  = getOI(strike_p5,  DateString, agg, "P");
def put_oi_p6  = getOI(strike_p6,  DateString, agg, "P");
def put_oi_p7  = getOI(strike_p7,  DateString, agg, "P");
def put_oi_p8  = getOI(strike_p8,  DateString, agg, "P");
def put_oi_p9  = getOI(strike_p9,  DateString, agg, "P");
def put_oi_p10 = getOI(strike_p10, DateString, agg, "P");

# GEX
def gex_m10 = Round(gamma_m10 * (call_oi_m10 - put_oi_m10) * S / 10000, 0);
def gex_m9  = Round(gamma_m9  * (call_oi_m9  - put_oi_m9 ) * S / 10000, 0);
def gex_m8  = Round(gamma_m8  * (call_oi_m8  - put_oi_m8 ) * S / 10000, 0);
def gex_m7  = Round(gamma_m7  * (call_oi_m7  - put_oi_m7 ) * S / 10000, 0);
def gex_m6  = Round(gamma_m6  * (call_oi_m6  - put_oi_m6 ) * S / 10000, 0);
def gex_m5  = Round(gamma_m5  * (call_oi_m5  - put_oi_m5 ) * S / 10000, 0);
def gex_m4  = Round(gamma_m4  * (call_oi_m4  - put_oi_m4 ) * S / 10000, 0);
def gex_m3  = Round(gamma_m3  * (call_oi_m3  - put_oi_m3 ) * S / 10000, 0);
def gex_m2  = Round(gamma_m2  * (call_oi_m2  - put_oi_m2 ) * S / 10000, 0);
def gex_m1  = Round(gamma_m1  * (call_oi_m1  - put_oi_m1 ) * S / 10000, 0);
def gex_0   = Round(gamma_0   * (call_oi_0   - put_oi_0  ) * S / 10000, 0);
def gex_p1  = Round(gamma_p1  * (call_oi_p1  - put_oi_p1 ) * S / 10000, 0);
def gex_p2  = Round(gamma_p2  * (call_oi_p2  - put_oi_p2 ) * S / 10000, 0);
def gex_p3  = Round(gamma_p3  * (call_oi_p3  - put_oi_p3 ) * S / 10000, 0);
def gex_p4  = Round(gamma_p4  * (call_oi_p4  - put_oi_p4 ) * S / 10000, 0);
def gex_p5  = Round(gamma_p5  * (call_oi_p5  - put_oi_p5 ) * S / 10000, 0);
def gex_p6  = Round(gamma_p6  * (call_oi_p6  - put_oi_p6 ) * S / 10000, 0);
def gex_p7  = Round(gamma_p7  * (call_oi_p7  - put_oi_p7 ) * S / 10000, 0);
def gex_p8  = Round(gamma_p8  * (call_oi_p8  - put_oi_p8 ) * S / 10000, 0);
def gex_p9  = Round(gamma_p9  * (call_oi_p9  - put_oi_p9 ) * S / 10000, 0);
def gex_p10 = Round(gamma_p10 * (call_oi_p10 - put_oi_p10) * S / 10000, 0);

# Plot horizontal bars for each strike
plot bar_m10 = if AbsValue(gex_m10) > min_gex then gex_m10 else Double.NaN;
plot bar_m9  = if AbsValue(gex_m9 ) > min_gex then gex_m9  else Double.NaN;
plot bar_m8  = if AbsValue(gex_m8 ) > min_gex then gex_m8  else Double.NaN;
plot bar_m7  = if AbsValue(gex_m7 ) > min_gex then gex_m7  else Double.NaN;
plot bar_m6  = if AbsValue(gex_m6 ) > min_gex then gex_m6  else Double.NaN;
plot bar_m5  = if AbsValue(gex_m5 ) > min_gex then gex_m5  else Double.NaN;
plot bar_m4  = if AbsValue(gex_m4 ) > min_gex then gex_m4  else Double.NaN;
plot bar_m3  = if AbsValue(gex_m3 ) > min_gex then gex_m3  else Double.NaN;
plot bar_m2  = if AbsValue(gex_m2 ) > min_gex then gex_m2  else Double.NaN;
plot bar_m1  = if AbsValue(gex_m1 ) > min_gex then gex_m1  else Double.NaN;
plot bar_0   = if AbsValue(gex_0  ) > min_gex then gex_0   else Double.NaN;
plot bar_p1  = if AbsValue(gex_p1 ) > min_gex then gex_p1  else Double.NaN;
plot bar_p2  = if AbsValue(gex_p2 ) > min_gex then gex_p2  else Double.NaN;
plot bar_p3  = if AbsValue(gex_p3 ) > min_gex then gex_p3  else Double.NaN;
plot bar_p4  = if AbsValue(gex_p4 ) > min_gex then gex_p4  else Double.NaN;
plot bar_p5  = if AbsValue(gex_p5 ) > min_gex then gex_p5  else Double.NaN;
plot bar_p6  = if AbsValue(gex_p6 ) > min_gex then gex_p6  else Double.NaN;
plot bar_p7  = if AbsValue(gex_p7 ) > min_gex then gex_p7  else Double.NaN;
plot bar_p8  = if AbsValue(gex_p8 ) > min_gex then gex_p8  else Double.NaN;
plot bar_p9  = if AbsValue(gex_p9 ) > min_gex then gex_p9  else Double.NaN;
plot bar_p10 = if AbsValue(gex_p10) > min_gex then gex_p10 else Double.NaN;

bar_m10.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
bar_m10.AssignValueColor(if gex_m10 > 0 then Color.GREEN else Color.RED);
bar_m10.SetLineWeight(5);
bar_m9.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
bar_m9.AssignValueColor(if gex_m9 > 0 then Color.GREEN else Color.RED);
bar_m9.SetLineWeight(5);
bar_m8.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
bar_m8.AssignValueColor(if gex_m8 > 0 then Color.GREEN else Color.RED);
bar_m8.SetLineWeight(5);
bar_m7.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
bar_m7.AssignValueColor(if gex_m7 > 0 then Color.GREEN else Color.RED);
bar_m7.SetLineWeight(5);
bar_m6.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
bar_m6.AssignValueColor(if gex_m6 > 0 then Color.GREEN else Color.RED);
bar_m6.SetLineWeight(5);
bar_m5.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
bar_m5.AssignValueColor(if gex_m5 > 0 then Color.GREEN else Color.RED);
bar_m5.SetLineWeight(5);
bar_m4.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
bar_m4.AssignValueColor(if gex_m4 > 0 then Color.GREEN else Color.RED);
bar_m4.SetLineWeight(5);
bar_m3.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
bar_m3.AssignValueColor(if gex_m3 > 0 then Color.GREEN else Color.RED);
bar_m3.SetLineWeight(5);
bar_m2.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
bar_m2.AssignValueColor(if gex_m2 > 0 then Color.GREEN else Color.RED);
bar_m2.SetLineWeight(5);
bar_m1.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
bar_m1.AssignValueColor(if gex_m1 > 0 then Color.GREEN else Color.RED);
bar_m1.SetLineWeight(5);
bar_0.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
bar_0.AssignValueColor(if gex_0 > 0 then Color.GREEN else Color.RED);
bar_0.SetLineWeight(5);
bar_p1.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
bar_p1.AssignValueColor(if gex_p1 > 0 then Color.GREEN else Color.RED);
bar_p1.SetLineWeight(5);
bar_p2.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
bar_p2.AssignValueColor(if gex_p2 > 0 then Color.GREEN else Color.RED);
bar_p2.SetLineWeight(5);
bar_p3.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
bar_p3.AssignValueColor(if gex_p3 > 0 then Color.GREEN else Color.RED);
bar_p3.SetLineWeight(5);
bar_p4.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
bar_p4.AssignValueColor(if gex_p4 > 0 then Color.GREEN else Color.RED);
bar_p4.SetLineWeight(5);
bar_p5.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
bar_p5.AssignValueColor(if gex_p5 > 0 then Color.GREEN else Color.RED);
bar_p5.SetLineWeight(5);
bar_p6.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
bar_p6.AssignValueColor(if gex_p6 > 0 then Color.GREEN else Color.RED);
bar_p6.SetLineWeight(5);
bar_p7.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
bar_p7.AssignValueColor(if gex_p7 > 0 then Color.GREEN else Color.RED);
bar_p7.SetLineWeight(5);
bar_p8.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
bar_p8.AssignValueColor(if gex_p8 > 0 then Color.GREEN else Color.RED);
bar_p8.SetLineWeight(5);
bar_p9.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
bar_p9.AssignValueColor(if gex_p9 > 0 then Color.GREEN else Color.RED);
bar_p9.SetLineWeight(5);
bar_p10.SetPaintingStrategy(PaintingStrategy.HORIZONTAL);
bar_p10.AssignValueColor(if gex_p10 > 0 then Color.GREEN else Color.RED);
bar_p10.SetLineWeight(5);

AddLabel(yes, "GEX (10 closest strikes) - Exp: " + Expiration_YYMMDD, Color.YELLOW);
