static NSString *const kMapAttackHostname = @"192.168.10.18";
static int const kMapAttackUdpPort = 5309;
static int const kMapAttackTcpPort = 8080;
#define kMapAttackURL [NSString stringWithFormat:@"http://%@:%d", kMapAttackHostname, kMapAttackTcpPort]

static NSString * const kDeviceIdKey = @"com.esri.portland.mapattack.deviceId";
static NSString * const kUserNameKey = @"com.esri.portland.mapattack.userName";
static NSString * const kAvatarKey = @"com.esri.portland.mapattack.avatar";
static NSString * const kAccessTokenKey = @"com.esri.portland.mapattack.accessToken";
