// Tweak.xm - aovnet menu -> "Menu Sushi" crimson, applied live in memory.
//
// The dylib carries a protector (__PROTECT,__integrity magic "XMPT",
// __virt_map, __virt_entries, __host_manifest). A single byte changed in
// __TEXT,__const kills the menu, even though XMPT only stores digests for
// __TEXT,__text and __PROTECT,__dcb_trap - so the protector watches more
// than it advertises. Never touch the file: find the ImGuiCol table in
// memory and rewrite the floats there.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <mach/vm_region.h>
#import <math.h>
#import <string.h>

// 64-byte fingerprint taken from the live ImGuiCol table, 0x2B0 bytes in.
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
static const int kSigRel = 0x2B0;

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

static vm_address_t gTables[16];
static int gTableCount = 0;
static int gTicks = 0;
static int gLogged = 0;

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

static int applyTable(vm_address_t table) {
    int n = 0;
    for (size_t i = 0; i < kSlotCount; i++) {
        const slot_t *s = &kSlots[i];
        float *f = (float *)(table + s->rel);
        if (slotIsNew(f, s)) { n++; continue; }   // already recoloured
        if (!slotIsOld(f, s)) continue;           // layout moved, leave it alone
        f[0] = s->nr; f[1] = s->ng; f[2] = s->nb; // alpha untouched
        n++;
    }
    return n;
}

static void scanRegion(vm_address_t base, vm_size_t size) {
    unsigned char *p = (unsigned char *)base;
    unsigned char *last = p + size - sizeof(kSig);
    for (unsigned char *q = p; q <= last; q += 4) {
        if (q[0] != kSig[0] || q[16] != kSig[16]) continue;
        if (memcmp(q, kSig, sizeof(kSig)) != 0) continue;
        vm_address_t table = (vm_address_t)(q - kSigRel);
        for (int i = 0; i < gTableCount; i++)
            if (gTables[i] == table) goto next;
        if (gTableCount < (int)(sizeof(gTables) / sizeof(gTables[0]))) {
            gTables[gTableCount++] = table;
            NSLog(@"[recolor] ImGuiCol table @ 0x%lx", (unsigned long)table);
        }
    next:;
    }
}

static void walkAndScan(void) {
    vm_address_t addr = 0;
    for (;;) {
        vm_size_t size = 0;
        vm_region_basic_info_data_64_t info;
        mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
        mach_port_t object = MACH_PORT_NULL;
        kern_return_t kr = vm_region_64(mach_task_self(), &addr, &size,
                                        VM_REGION_BASIC_INFO_64,
                                        (vm_region_info_t)&info, &count, &object);
        if (kr != KERN_SUCCESS) break;
        vm_prot_t want = VM_PROT_READ | VM_PROT_WRITE;
        if ((info.protection & want) == want &&
            size >= 0x1000 && size <= (256u << 20)) {
            scanRegion(addr, size);
        }
        addr += size;
        if (addr == 0) break;
    }
}

static void tick(void) {
    gTicks++;
    // A full walk is a few hundred MB of memcmp - do it sparingly, and only
    // while the table is still missing (~30 s of hunting).
    if (gTableCount == 0 && gTicks <= 40 && (gTicks & 1)) walkAndScan();

    int slots = 0;
    for (int i = 0; i < gTableCount; i++) slots += applyTable(gTables[i]);
    if (slots && !gLogged) {
        gLogged = 1;
        NSLog(@"[recolor] crimson applied: %d/%d slots over %d table(s)",
              slots, (int)kSlotCount, gTableCount);
    }
}

__attribute__((constructor))
static void recolor_init(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimer *t = [NSTimer scheduledTimerWithTimeInterval:0.75 repeats:YES
                                                       block:^(NSTimer *tm) { (void)tm; tick(); }];
        [[NSRunLoop mainRunLoop] addTimer:t forMode:NSRunLoopCommonModes];
        NSLog(@"[recolor] armed");
    });
}
