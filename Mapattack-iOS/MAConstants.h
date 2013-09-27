extern NSString *const kMapAttackHostname;
static int const kMapAttackUdpPort = 5309;
static int const kMapAttackTcpPort = 8080;
#define kMapAttackURL [NSString stringWithFormat:@"http://%@:%d", kMapAttackHostname, kMapAttackTcpPort]

static NSString * const kDeviceIdKey = @"com.esri.portland.mapattack.deviceId";
static NSString * const kUserNameKey = @"com.esri.portland.mapattack.userName";
static NSString * const kAvatarKey = @"com.esri.portland.mapattack.avatar";
static NSString * const kAccessTokenKey = @"com.esri.portland.mapattack.accessToken";
static NSString * const kPushTokenKey = @"com.esri.portland.mapattack.pushToken";

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

typedef enum {
    MAPushTokenTypeSandbox,
    MAPushTokenTypeProduction
} MAPushTokenType;

static MAPushTokenType *const kPushTokenType = MAPushTokenTypeSandbox;