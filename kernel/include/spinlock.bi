#pragma once

#include once "kernel.bi"

type spinlock as integer

declare sub spinlock_acquire (slock as spinlock ptr)
declare function spinlock_trylock (slock as spinlock ptr) as boolean
declare sub spinlock_release (slock as spinlock ptr)
declare function spinlock_locked (slock as spinlock ptr) as boolean
