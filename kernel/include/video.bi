/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2013  Stefan Schmidt
 '
 ' This program is free software: you can redistribute it and/or modify
 ' it under the terms of the GNU General Public License as published by
 ' the Free Software Foundation, either version 3 of the License, or
 ' (at your option) any later version.
 '
 ' This program is distributed in the hope that it will be useful,
 ' but WITHOUT ANY WARRANTY; without even the implied warranty of
 ' MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 ' GNU General Public License for more details.
 '
 ' You should have received a copy of the GNU General Public License
 ' along with this program.  If not, see <http://www.gnu.org/licenses/>.
 '/

#pragma once

#define LOG_DEBUG !"\0022"
#define LOG_INFO !"\0021"
#define LOG_ERR !"\0020"

#define LOGLEVEL_DEBUG 2
#define LOGLEVEL_INFO 1
#define LOGLEVEL_ERR 0

#define COLOR_BLACK !"\27[30m"
#define COLOR_RED !"\27[31m"
#define COLOR_GREEN !"\27[32m"
#define COLOR_YELLOW !"\27[33m"
#define COLOR_BLUE !"\27[34m"
#define COLOR_MAGENTA !"\27[35m"
#define COLOR_CYAN !"\27[36m"
#define COLOR_WHITE !"\27[37m"
#define COLOR_RESET !"\27[0m"

declare sub video_serial_set_colorized (b as integer)
declare sub printk (format_string as const zstring, ...)
declare sub video_clean ()
declare sub video_hide_cursor ()
declare sub video_show_cursor ()
declare sub video_move_cursor (x as ubyte, y as ubyte)
