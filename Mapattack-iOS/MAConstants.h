extern NSString *const kMapAttackHostname;
static int const kMapAttackUdpPort = 5309;
static int const kMapAttackTcpPort = 8080;
#define MAPATTACK_URL [NSString stringWithFormat:@"http://%@:%d", kMapAttackHostname, kMapAttackTcpPort]

static int const kMAGameStatePollingInterval = 15;
static double const kMARealTimeDistanceFilter = 1;
static double const kMAGameListDistanceFilter = 50;

static NSUInteger const kMAMaxUsernameLength = 3;
static float const kMAAvatarSize = 256.0f;
static float const kMAAvatarIconSize = 55.0f;

/* UserDefaults keys
 */
static NSString * const kMADefaultsDomain = @"com.esri.portland.mapattack";
static NSString * const kMADefaultsDeviceIdKey = @"com.esri.portland.mapattack.deviceId";
static NSString * const kMADefaultsUserNameKey = @"com.esri.portland.mapattack.userName";
static NSString * const kMADefaultsAvatarKey = @"com.esri.portland.mapattack.avatar";
static NSString * const kMADefaultsAccessTokenKey = @"com.esri.portland.mapattack.accessToken";
static NSString * const kMADefaultsPushTokenKey = @"com.esri.portland.mapattack.pushToken";
static NSString *const kMADefaultsAvatarIndexKey = @"com.esri.portland.mapattack.defaultAvatarIndex";
static NSString *const kMADefaultsDefaultAvatarSelectedKey = @"com.esri.portland.mapattack.defaultAvatarSelected";

/* API paths
 */
static NSString *const kMAApiDeviceRegisterPath = @"/device/register";
static NSString *const kMAApiDeviceRegisterPushPath = @"/device/register_push";
static NSString *const kMAApiBoardListPath = @"/board/list";
static NSString *const kMAApiBoardStatePath = @"/board/state";
static NSString *const kMAApiGameJoinPath = @"/game/join";
static NSString *const kMAApiGameCreatePath = @"/game/create";
static NSString *const kMAApiGameStartPath = @"/game/start";
static NSString *const kMAApiGameEndPath = @"/game/end";
static NSString *const kMAApiGameStatePath = @"/game/state";

/* API keys
 */
static NSString *const kMAApiAccessTokenKey = @"access_token";
static NSString *const kMAApiAvatarKey = @"avatar";
static NSString *const kMAApiDeviceIdKey = @"device_id";
static NSString *const kMAApiNameKey = @"name";
static NSString *const kMAApiBoardIdKey = @"board_id";
static NSString *const kMAApiBoardKey = @"board";
static NSString *const kMAApiCoinsKey = @"coins";
static NSString *const kMAApiCoinIdKey = @"coin_id";
static NSString *const kMAApiGameKey = @"game";
static NSString *const kMAApiGameIdKey = @"game_id";
static NSString *const kMAApiTeamKey = @"team";
static NSString *const kMAApiTeamsKey = @"teams";
static NSString *const kMAApiActiveKey = @"active";
static NSString *const kMAApiErrorKey = @"error";
static NSString *const kMAApiErrorCodeKey = @"code";
static NSString *const kMAApiLatitudeKey = @"latitude";
static NSString *const kMAApiLongitudeKey = @"longitude";
static NSString *const kMAApiTimestampKey = @"timestamp";
static NSString *const kMAApiAccuracyKey = @"accuracy";
static NSString *const kMAApiSpeedKey = @"speed";
static NSString *const kMAApiBearingKey = @"bearing";
static NSString *const kMAApiPlayersKey = @"players";
static NSString *const kMAApiScoreKey = @"score";
static NSString *const kMAApiPointsKey = @"value";
static NSString *const kMAApiRedKey = @"red";
static NSString *const kMAApiBlueKey = @"blue";
static NSString *const kMAApiRedScoreKey = @"red_score";
static NSString *const kMAApiBlueScoreKey = @"blue_score";
static NSString *const kMAApiPlayerScoreKey = @"player_score";
static NSString *const kMAApiBoundingBoxKey = @"bbox";
static NSString *const kMAApiApnsSandboxTokenKey = @"apns_sandbox_token";
static NSString *const kMAApiApnsProductionTokenKey = @"apns_prod_token";

/* Color helpers
 */
UIColor *_colorWithHexString(NSString *hex);

#define MA_COLOR_WHITE _colorWithHexString(@"ffffff")
#define MA_COLOR_OFFWHITE _colorWithHexString(@"fefefe")
#define MA_COLOR_LIGHTGRAY _colorWithHexString(@"dddddd")
#define MA_COLOR_DARKGRAY _colorWithHexString(@"30302f")
#define MA_COLOR_DARKERGRAY _colorWithHexString(@"242323")
#define MA_COLOR_DARKESTGRAY _colorWithHexString(@"222222")
#define MA_COLOR_CREAM _colorWithHexString(@"fffbf2")
#define MA_COLOR_RED _colorWithHexString(@"f54130")
#define MA_COLOR_BLUE _colorWithHexString(@"5498e8")
#define MA_COLOR_DARKBLUE _colorWithHexString(@"1e6aca")
#define MA_COLOR_BODYBLUE _colorWithHexString(@"3988e4")

/* Font helpers 
 */
UIFont *_fontWithFaceAndSize(NSString *face, float size);

#define MA_FONT_MENSCH_HEADER _fontWithFaceAndSize(@"mensch", 32.0f)
#define MA_FONT_MENSCH_REGULAR _fontWithFaceAndSize(@"mensch", 18.0f)
#define MA_FONT_KARLA_HEADER _fontWithFaceAndSize(@"karla", 32.0f)
#define MA_FONT_KARLA_REGULAR _fontWithFaceAndSize(@"karla", 18.0f)
#define MA_FONT_LOVEBIT_HEADER _fontWithFaceAndSize(@"M41_LOVEBIT", 32.0f)
#define MA_FONT_LOVEBIT_REGULAR _fontWithFaceAndSize(@"M41_LOVEBIT", 18.0f)

/* Push Notification token types
 */
typedef enum {
    MAPushTokenTypeSandbox,
    MAPushTokenTypeProduction
} MAPushTokenType;

static MAPushTokenType const kPushTokenType = MAPushTokenTypeSandbox;