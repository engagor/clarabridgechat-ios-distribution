//
//  CLBMacros.h
//  ClarabridgeChat
//
//  Created by Alan Egan on 02/12/2019.
//  Copyright © 2019 Smooch Technologies. All rights reserved.
//

#ifndef CLBMacros_h
#define CLBMacros_h

#ifndef CLB_FINAL_CLASS
#if defined(__has_attribute) && __has_attribute(objc_subclassing_restricted)
# define CLB_FINAL_CLASS __attribute__((objc_subclassing_restricted))
#else
# define CLB_FINAL_CLASS
#endif
#endif

#endif /* CLBMacros_h */
