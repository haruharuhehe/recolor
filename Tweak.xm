// recolor - aovnet menu -> "Menu Sushi" crimson, applied live in memory.
//
// Why runtime and not a hex patch: aovnet carries a protector
// (__PROTECT,__integrity "XMPT", __virt_map, __virt_entries,
// __host_manifest). One changed byte anywhere in __TEXT kills the menu.
//
// Why no scanning: the old version walked every mapped region on the main
// thread and froze the game into a black screen right after the splash.
// The table sits at a fixed file offset inside aovnet's __TEXT, and __TEXT
// has vmaddr 0, so once dyld tells us where the image landed the table
// address is just image_base + 0x2861070. Nothing to scan.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <mach/vm_region.h>
#import <mach/vm_page_size.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <math.h>
#import <string.h>

static const unsigned char kSig[] = {
    0xEC, 0x51, 0x38, 0x3E, 0xC3, 0xF5, 0x28, 0x3F,
    0x29, 0x5C, 0x0F, 0x3F, 0x00, 0x00, 0x80, 0x3F,
    0xCD, 0xCC, 0xCC, 0x3E, 0xF6, 0x28, 0xDC, 0x3E,
    0xD7, 0xA3, 0xF0, 0x3E, 0x00, 0x00, 0x80, 0x3F,
    0x66, 0x66, 0x66, 0x3F, 0x7B, 0x14, 0x6E, 0x3F,
    0x33, 0x33, 0x73, 0x3F, 0x00, 0x00, 0x80, 0x3F,
    0xEC, 0x51, 0xB8, 0x3D, 0xB8, 0x1E, 0x05, 0x3E,
    0x8F, 0xC2, 0xF5, 0x3D, 0x00, 0x00, 0x80, 0x3F,
};


typedef struct { int rel; float or_, og, ob, nr, ng, nb; } slot_t;

// rel, old RGB, new RGB
static const slot_t kSlots[] = {
    { 0x000, 0.200000003f, 0.200000003f, 0.200000003f,  0.164705887f, 0.164705887f, 0.200000003f },
    { 0x010, 0.200000003f, 0.200000003f, 0.200000003f,  0.164705887f, 0.164705887f, 0.200000003f },
    { 0x020, 0.600000024f, 0.750000000f, 0.779999971f,  0.780392170f, 0.788235307f, 0.819607854f },
    { 0x030, 0.00000000f, 0.779999971f, 0.879999995f,  0.662745118f, 0.00000000f, 0.125490203f },
    { 0x040, 0.00000000f, 0.479999989f, 0.560000002f,  0.490196079f, 0.0627451017f, 0.160784319f },
    { 0x050, 0.00000000f, 0.720000029f, 0.819999993f,  0.662745118f, 0.00000000f, 0.125490203f },
    { 0x060, 0.119999997f, 0.180000007f, 0.180000007f,  0.121568628f, 0.0823529437f, 0.125490203f },
    { 0x080, 0.349999994f, 0.479999989f, 0.500000000f,  0.486274511f, 0.498039216f, 0.549019635f },
    { 0x090, 0.500000000f, 0.649999976f, 0.680000007f,  0.705882370f, 0.713725507f, 0.752941191f },
    { 0x0A0, 0.800000012f, 0.860000014f, 0.860000014f,  0.862745106f, 0.866666675f, 0.886274517f },
    { 0x0B0, 0.00000000f, 0.680000007f, 0.779999971f,  0.643137276f, 0.00000000f, 0.121568628f },
    { 0x0C0, 0.00000000f, 0.699999988f, 0.819999993f,  0.662745118f, 0.00000000f, 0.125490203f },
    { 0x0D0, 0.00000000f, 0.600000024f, 0.699999988f,  0.584313750f, 0.0627451017f, 0.164705887f },
    { 0x0E0, 0.449999988f, 0.649999976f, 0.680000007f,  0.631372571f, 0.639215708f, 0.682352960f },
    { 0x0F0, 0.00000000f, 0.720000029f, 0.819999993f,  0.662745118f, 0.00000000f, 0.125490203f },
    { 0x100, 0.449999988f, 0.600000024f, 0.620000005f,  0.603921592f, 0.611764729f, 0.658823550f },
    { 0x110, 0.00000000f, 0.639999986f, 0.740000010f,  0.635294139f, 0.00000000f, 0.117647059f },
    { 0x120, 0.00000000f, 0.579999983f, 0.680000007f,  0.627451003f, 0.00000000f, 0.113725491f },
    { 0x130, 0.00000000f, 0.579999983f, 0.680000007f,  0.627451003f, 0.00000000f, 0.113725491f },
    { 0x140, 0.00000000f, 0.639999986f, 0.740000010f,  0.635294139f, 0.00000000f, 0.117647059f },
    { 0x150, 0.920000017f, 0.959999979f, 0.959999979f,  0.905882359f, 0.905882359f, 0.917647064f },
    { 0x160, 0.00000000f, 0.649999976f, 0.759999990f,  0.647058845f, 0.00000000f, 0.121568628f },
    { 0x170, 0.00000000f, 0.550000012f, 0.639999986f,  0.549019635f, 0.0627451017f, 0.156862751f },
    { 0x180, 0.100000001f, 0.159999996f, 0.180000007f,  0.137254909f, 0.0901960805f, 0.149019614f },
    { 0x190, 0.159999996f, 0.300000012f, 0.340000004f,  0.227450982f, 0.164705887f, 0.200000003f },
    { 0x1A0, 0.180000007f, 0.259999990f, 0.300000012f,  0.200000003f, 0.141176477f, 0.172549024f },
    { 0x1B0, 0.150000006f, 0.150000006f, 0.200000003f,  0.149019614f, 0.156862751f, 0.203921571f },
    { 0x1C0, 0.00000000f, 0.620000005f, 0.720000029f,  0.639215708f, 0.00000000f, 0.117647059f },
    { 0x1D0, 0.150000006f, 0.150000006f, 0.200000003f,  0.149019614f, 0.156862751f, 0.203921571f },
    { 0x1F0, 0.100000001f, 0.100000001f, 0.150000006f,  0.101960786f, 0.109803922f, 0.156862751f },
    { 0x280, 0.180000007f, 0.660000026f, 0.560000002f,  0.662745118f, 0.00000000f, 0.125490203f },
    { 0x2A0, 0.129999995f, 0.150000006f, 0.180000007f,  0.129411772f, 0.141176477f, 0.184313729f },
    { 0x2B0, 0.180000007f, 0.660000026f, 0.560000002f,  0.662745118f, 0.00000000f, 0.125490203f },
    { 0x2C0, 0.400000006f, 0.430000007f, 0.469999999f,  0.537254930f, 0.545098066f, 0.584313750f },
    { 0x2D0, 0.899999976f, 0.930000007f, 0.949999988f,  0.905882359f, 0.905882359f, 0.917647064f },
    { 0x2E0, 0.0900000036f, 0.129999995f, 0.119999997f,  0.164705887f, 0.109803922f, 0.141176477f },
    { 0x2F0, 0.180000007f, 0.660000026f, 0.560000002f,  0.662745118f, 0.00000000f, 0.125490203f },
    { 0x300, 0.0900000036f, 0.109999999f, 0.129999995f,  0.0901960805f, 0.0980392173f, 0.137254909f },
    { 0x310, 0.180000007f, 0.660000026f, 0.560000002f,  0.662745118f, 0.00000000f, 0.125490203f },
    { 0x320, 0.180000007f, 0.660000026f, 0.560000002f,  0.662745118f, 0.00000000f, 0.125490203f },
    { 0x330, 0.180000007f, 0.660000026f, 0.560000002f,  0.662745118f, 0.00000000f, 0.125490203f },
    { 0x340, 0.129999995f, 0.150000006f, 0.180000007f,  0.129411772f, 0.141176477f, 0.184313729f },
    { 0x350, 0.180000007f, 0.660000026f, 0.560000002f,  0.662745118f, 0.00000000f, 0.125490203f },
    { 0x360, 0.180000007f, 0.660000026f, 0.560000002f,  0.662745118f, 0.00000000f, 0.125490203f },
    { 0x370, 0.100000001f, 0.180000007f, 0.159999996f,  0.286274523f, 0.196078435f, 0.227450982f },
    { 0x380, 0.140000001f, 0.550000012f, 0.460000008f,  0.490196079f, 0.0627451017f, 0.160784319f },
    { 0x390, 0.180000007f, 0.660000026f, 0.560000002f,  0.662745118f, 0.00000000f, 0.125490203f },
    { 0x3A0, 0.180000007f, 0.660000026f, 0.560000002f,  0.662745118f, 0.00000000f, 0.125490203f },
    { 0x3B0, 0.239999995f, 0.740000010f, 0.629999995f,  0.752941191f, 0.00000000f, 0.141176477f },
    { 0x3C0, 0.180000007f, 0.660000026f, 0.560000002f,  0.662745118f, 0.00000000f, 0.125490203f },
    { 0x3D0, 0.250000000f, 0.280000001f, 0.319999993f,  0.243137255f, 0.254901975f, 0.301960796f },
    { 0x3E0, 0.200000003f, 0.219999999f, 0.259999990f,  0.203921571f, 0.215686277f, 0.266666681f },
    { 0x3F0, 0.0500000007f, 0.0700000003f, 0.0900000036f,  0.0509803928f, 0.0588235296f, 0.0862745121f },
    { 0x400, 0.0500000007f, 0.0700000003f, 0.0900000036f,  0.0509803928f, 0.0588235296f, 0.0862745121f },
    { 0x410, 0.0700000003f, 0.0900000036f, 0.109999999f,  0.0666666701f, 0.0784313753f, 0.113725491f },
    { 0x420, 0.0500000007f, 0.0700000003f, 0.0900000036f,  0.0509803928f, 0.0588235296f, 0.0862745121f },
    { 0x430, 0.159999996f, 0.189999998f, 0.230000004f,  0.164705887f, 0.172549024f, 0.219607845f },
    { 0x440, 0.140000001f, 0.159999996f, 0.200000003f,  0.141176477f, 0.152941182f, 0.196078435f },
    { 0x450, 0.109999999f, 0.129999995f, 0.159999996f,  0.105882354f, 0.117647059f, 0.160784319f },
    { 0x460, 0.129999995f, 0.150000006f, 0.180000007f,  0.129411772f, 0.141176477f, 0.184313729f },
    { 0x470, 0.0900000036f, 0.109999999f, 0.129999995f,  0.0901960805f, 0.0980392173f, 0.137254909f },
    { 0x480, 0.0500000007f, 0.0700000003f, 0.0900000036f,  0.0509803928f, 0.0588235296f, 0.0862745121f },
};
static const size_t kSlotCount = sizeof(kSlots) / sizeof(kSlots[0]);

#define kTableOffset 0x2861070ULL   // ImGuiCol table, from aovnet image base
#define kTableSpan   0x500          // last slot sits at 0x480 + 16 bytes

static dispatch_queue_t gQueue;
static dispatch_source_t gTimer;
static vm_address_t gTable = 0;
static int gWritable = 0;
static int gTicks = 0;
static int gLogged = 0;
static int gAlerted = 0;

static inline BOOL slotIsOld(const float *f, const slot_t *s) {
    return fabsf(f[0] - s->or_) < 1e-4f &&
           fabsf(f[1] - s->og)  < 1e-4f &&
           fabsf(f[2] - s->ob)  < 1e-4f;
}

static inline BOOL slotIsNew(const float *f, const slot_t *s) {
    return fabsf(f[0] - s->nr) < 1e-4f &&
           fabsf(f[1] - s->ng) < 1e-4f &&
           fabsf(f[2] - s->nb) < 1e-4f;
}

// Ask dyld where aovnet landed, then read the table straight out of its
// __TEXT at a known offset. Cheap, safe, and works however it was loaded.
static vm_address_t locateTable(void) {
    uint32_t n = _dyld_image_count();
    for (uint32_t i = 0; i < n; i++) {
        const char *name = _dyld_get_image_name(i);
        if (!name || !strstr(name, "aovnet")) continue;
        const struct mach_header_64 *h =
            (const struct mach_header_64 *)_dyld_get_image_header(i);
        if (!h) continue;
        vm_address_t table = (vm_address_t)h + kTableOffset;
        if (memcmp((const void *)(table + kSigRel), kSig, sizeof(kSig)) == 0)
            return table;
        NSLog(@"[recolor] %s found, but the table signature does not match", name);
    }
    return 0;
}

static BOOL makeWritable(vm_address_t table) {
    vm_address_t lo = table & ~(vm_address_t)(vm_page_size - 1);
    vm_address_t hi = (table + kTableSpan + vm_page_size - 1) &
                      ~(vm_address_t)(vm_page_size - 1);
    kern_return_t kr = vm_protect(mach_task_self(), lo, hi - lo, FALSE,
                                  VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (kr != KERN_SUCCESS) {
        NSLog(@"[recolor] vm_protect failed (%d) at 0x%lx", kr, (unsigned long)lo);
        return NO;
    }
    return YES;
}

static int applyTable(vm_address_t table) {
    int n = 0;
    for (size_t i = 0; i < kSlotCount; i++) {
        const slot_t *s = &kSlots[i];
        float *f = (float *)(table + s->rel);
        if (slotIsNew(f, s)) { n++; continue; }
        if (!slotIsOld(f, s)) continue;
        if (!gWritable) {
            if (!makeWritable(table)) return 0;
            gWritable = 1;
            NSLog(@"[recolor] made the __const page writable");
        }
        f[0] = s->nr; f[1] = s->ng; f[2] = s->nb;   // alpha untouched
        n++;
    }
    return n;
}

static void tick(void) {   // always runs on gQueue, never on main
    gTicks++;
    if (!gTable) gTable = locateTable();

    if (gTable) {
        int n = applyTable(gTable);
        if (n && !gLogged) {
            gLogged = 1;
            NSLog(@"[recolor] crimson applied: %d/%d slots", n, (int)kSlotCount);
        }
        return;
    }

    // Still nothing after ~20 s: tell the user without needing a log viewer.
    if (gTicks == 20 && !gAlerted) {
        gAlerted = 1;
        dispatch_async(dispatch_get_main_queue(), ^{
            UIWindow *key = nil;
            for (UIWindow *w in UIApplication.sharedApplication.windows)
                if (w.isKeyWindow) { key = w; break; }
            if (!key) key = UIApplication.sharedApplication.windows.firstObject;
            UIViewController *vc = key.rootViewController;
            if (!vc) return;
            UIAlertController *a = [UIAlertController
                alertControllerWithTitle:@"recolor"
                                 message:@"dylib loaded, aovnet not found yet"
                          preferredStyle:UIAlertControllerStyleAlert];
            [a addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
            [vc presentViewController:a animated:YES completion:nil];
        });
    }
}

__attribute__((constructor))
static void recolor_init(void) {
    gQueue = dispatch_queue_create("com.olltaterfx.recolor", DISPATCH_QUEUE_SERIAL);
    gTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, gQueue);
    // First look at 4 s so the app gets through launch untouched, then 1 s.
    dispatch_source_set_timer(gTimer,
                              dispatch_time(DISPATCH_TIME_NOW, 4ull * NSEC_PER_SEC),
                              NSEC_PER_SEC, NSEC_PER_SEC / 2);
    dispatch_source_set_event_handler(gTimer, ^{ tick(); });
    dispatch_resume(gTimer);
    NSLog(@"[recolor] armed");
}
