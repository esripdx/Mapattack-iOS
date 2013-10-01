extern NSString *const kMapAttackHostname;
static int const kMapAttackUdpPort = 5309;
static int const kMapAttackTcpPort = 8080;
#define MAPATTACK_URL [NSString stringWithFormat:@"http://%@:%d", kMapAttackHostname, kMapAttackTcpPort]

static int const kMAGameStatePollingInterval = 15;

/* UserDefaults keys
 */
static NSString * const kMADefaultsDomain = @"com.esri.portland.mapattack";
static NSString * const kMADefaultsDeviceIdKey = @"com.esri.portland.mapattack.deviceId";
static NSString * const kMADefaultsUserNameKey = @"com.esri.portland.mapattack.userName";
static NSString * const kMADefaultsAvatarKey = @"com.esri.portland.mapattack.avatar";
static NSString * const kMADefaultsAccessTokenKey = @"com.esri.portland.mapattack.accessToken";
static NSString * const kMADefaultsPushTokenKey = @"com.esri.portland.mapattack.pushToken";

/* API paths
 */
static NSString * const kMAApiDeviceRegisterPath = @"/device/register";
static NSString * const kMAApiDeviceRegisterPushPath = @"/device/register_push";
static NSString * const kMAApiBoardListPath = @"/board/list";
static NSString * const kMAApiBoardStatePath = @"/board/state";
static NSString * const kMAApiGameJoinPath = @"/game/join";
static NSString * const kMAApiGameCreatePath = @"/game/create";
static NSString * const kMAApiGameStartPath = @"/game/start";
static NSString * const kMAApiGameEndPath = @"/game/end";
static NSString * const kMAApiGameStatePath = @"/game/state";

/* API keys
 */
static NSString * const kMAApiAccessTokenKey = @"access_token";

static NSString * const kMAApiAvatarKey = @"avatar";
static NSString * const kMAApiDeviceIdKey = @"device_id";

static NSString * const kMAApiNameKey = @"name";
static NSString * const kMAApiBoardIdKey = @"board_id";
static NSString * const kMAApiGameKey = @"game";
    static NSString * const kMAApiGameIdKey = @"game_id";
    static NSString * const kMAApiTeamKey = @"team";
    static NSString * const kMAApiActiveKey = @"active";

static NSString * const kMAApiErrorKey = @"error";
    static NSString * const kMAApiErrorCodeKey = @"code";

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

/* Push Notification toekn types
 */
typedef enum {
    MAPushTokenTypeSandbox,
    MAPushTokenTypeProduction
} MAPushTokenType;

static MAPushTokenType const kPushTokenType = MAPushTokenTypeSandbox;