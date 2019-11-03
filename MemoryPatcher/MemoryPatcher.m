//
//  MemoryPatcher.m
//  MemoryPatcher
//
//  Created by 江南 on 2019/11/2.
//  Copyright © 2019 江南. All rights reserved.
//

#import "MemoryPatcher.h"
#include <mach-o/dyld.h>
#include <mach/mach.h>
#import <objc/runtime.h>
typedef struct{
    uint64_t address;
    size_t size;
    uint64_t value;
}MemoryRestore;

typedef struct{
    uint64_t offests;
    uint64_t bytes;
    MemoryRestore restore;
}Patch;

Patch Patch1;


@implementation NSObject (hook)


+(void)load{
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //构造一个Patch
        MemoryRestore orig_value;
        orig_value.address = 0;
        orig_value.size = 0;
        orig_value.value = 0;
        
        Patch1.offests = 0x101D95DA0;
        Patch1.bytes = 0xD65F03C0;
        Patch1.restore = orig_value;
        
        //添加Switch
        UISwitch *mySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(100, 100, 100, 30)];
        mySwitch.on = NO;
        mySwitch.tintColor = [UIColor redColor];
        mySwitch.onTintColor = [UIColor blackColor];
        mySwitch.thumbTintColor = [UIColor blueColor];
        [mySwitch addTarget:self action:@selector(valueChanged:) forControlEvents:(UIControlEventValueChanged)];
        [[UIApplication sharedApplication].keyWindow addSubview:mySwitch];
		MemoryPatch2_64(0x101C4E020,0xD65F03C01E37F000);
		MemoryPatch2(0x101C22738,0xD65F03C0);
		MemoryPatch2(0x101D96384,0x1E2703E1);
		MemoryPatch2(0x1021C81FC,0xD65F03C0);
		MemoryPatch2(0x101D9638C,0x1E2703E0);
		MemoryPatch2(0x103A43138,0xD503201F);
		
		
    });
    
   
    
}

- (void)valueChanged:(UISwitch *)swi{
    
    if(swi.isOn){
        //启用Patch
    PatchEnabled(Patch1.offests,Patch1.bytes,&Patch1.restore);
    }else{
        //恢复内存
    PatchDisabled(&Patch1.restore);
    }
    
}
void MemoryRestored(MemoryRestore *restore);
void MemoryPatch(uint64_t TargetAddr,uint32_t Bytes,MemoryRestore *orig_value);
void MemoryPatch2(uint64_t TargetAddr,uint32_t Bytes);
void MemoryPatch64(uint64_t TargetAddr,uint64_t Bytes,MemoryRestore *orig_value);
void MemoryPatch2_64(uint64_t TargetAddr,uint64_t Bytes);
void PatchEnabled(uint64_t TargetAddr,uint64_t Bytes,MemoryRestore *orig_value);
void PatchDisabled(MemoryRestore *restore);

void PatchDisabled(MemoryRestore *restore){

MemoryRestored(restore);

}

void MemoryRestored(MemoryRestore *restore){
    
    int result = vm_protect(mach_task_self(),(vm_address_t)restore->address,restore->size,0,19);
    NSLog(@"------restore.address is %0llX\nrestore value is %X",restore->address,restore->value);
    memcpy((void *)restore->address,&restore->value,restore->size);
    result = vm_protect(mach_task_self(),(vm_address_t)restore->address,restore->size,0,VM_PROT_READ | VM_PROT_EXECUTE);
    NSLog(@"-----Restored Successfully");
    
}

void PatchEnabled(uint64_t TargetAddr,uint64_t Bytes,MemoryRestore *orig_value){
if(Bytes <= 0xFFFFFFFF){

MemoryPatch(TargetAddr,(uint32_t)Bytes,orig_value);

}else{

MemoryPatch64(TargetAddr,Bytes,orig_value);




}

void MemoryPatch(uint64_t TargetAddr,uint32_t Bytes,MemoryRestore *orig_value){
    
    uint64_t ASLR = _dyld_get_image_vmaddr_slide(0);
    uint64_t real_address = TargetAddr + ASLR;
    orig_value->size = sizeof(uint32_t);
    int result = vm_protect(mach_task_self(),(vm_address_t)real_address,orig_value->size,0,19);
    orig_value->address = real_address;
    orig_value->value = *((uint32_t *)real_address);
    NSLog(@"--------orig_value is %08X",orig_value->value);
    *((uint32_t *)real_address) = Bytes;
    NSLog(@"--------modfied into %08X",*((uint32_t *)real_address));
    result = vm_protect(mach_task_self(),(vm_address_t)real_address,orig_value->size,0,VM_PROT_READ | VM_PROT_EXECUTE); 
	
}
void MemoryPatch64(uint64_t TargetAddr,uint64_t Bytes,MemoryRestore *orig_value){

    uint64_t ASLR = _dyld_get_image_vmaddr_slide(0);
    uint64_t real_address = TargetAddr + ASLR;
    orig_value->size = sizeof(uint64_t);
    int result = vm_protect(mach_task_self(),(vm_address_t)real_address,orig_value->size,0,19);
    orig_value->address = real_address;
    orig_value->value = *((uint64_t *)real_address);
    NSLog(@"--------orig_value is %016lX",orig_value->value);
    *((uint64_t *)real_address) = Bytes;
    NSLog(@"--------modfied into %016lX",*((uint64_t *)real_address));
    result = vm_protect(mach_task_self(),(vm_address_t)real_address,orig_value->size,0,VM_PROT_READ | VM_PROT_EXECUTE); 

}

void MemoryPatch2_64(uint64_t TargetAddr,uint64_t Bytes){

    uint64_t ASLR = _dyld_get_image_vmaddr_slide(0);
    uint64_t real_address = TargetAddr + ASLR;
    int result = vm_protect(mach_task_self(),(vm_address_t)real_address,sizeof(uint64_t),0,19);
    NSLog(@"--------orig_value is %016lX",*((uint64_t *)real_address);
    *((uint64_t *)real_address) = Bytes;
    NSLog(@"--------modfied into %016lX",*((uint64_t *)real_address));
    result = vm_protect(mach_task_self(),(vm_address_t)real_address,sizeof(uint64_t),0,VM_PROT_READ | VM_PROT_EXECUTE);

}

void MemoryPatch2(uint64_t TargetAddr,uint32_t Bytes){
    
    uint64_t ASLR = _dyld_get_image_vmaddr_slide(0);
    uint64_t real_address = TargetAddr + ASLR;
    int result = vm_protect(mach_task_self(),(vm_address_t)real_address,sizeof(uint32_t),0,19);
    NSLog(@"--------orig_value is %08X",*((uint32_t *)real_address);
    *((uint32_t *)real_address) = Bytes;
    NSLog(@"--------modfied into %08X",*((uint32_t *)real_address));
    result = vm_protect(mach_task_self(),(vm_address_t)real_address,sizeof(uint32_t),0,VM_PROT_READ | VM_PROT_EXECUTE);
    
    
}



@end
