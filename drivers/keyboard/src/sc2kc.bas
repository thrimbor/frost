dim shared scancode_table (0 to 127) as ubyte = {  _
	 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, _
	10, 11, 12, 13, 14, 15, 16, 17, 18, 19, _
	20, 21, 22, 23, 24, 25, 26, 27, 28, 29, _
	30, 31, 32, 33, 34, 35, 36, 37, 38, 39, _
	40, 41, 42, 43, 44, 45, 46, 47, 48, 49, _
	50, 51, 52, 53, 54, 55, 56, 57, 58, 59, _
	60, 61, 62, 63, 64, 65, 66, 67, 68, 69, _
	70, 71, 72, 73, 74, 75, 76, 77, 78, 79, _
	80, 81, 82, 84, 00, 00, 86, 87, 88, 00, _
	00, 00, 00, 00, 00, 00, 00, 00, 00, 00, _
	00, 00, 00, 00, 00, 00, 00, 00, 00, 00, _
	00, 00, 00, 00, 00, 00, 00, 00, 00, 00, _
	00, 00, 00, 00, 00, 00, 00, 00 }

dim shared e0code_table (0 to 127) as ubyte = { _
	 00,   00,  00,  00,  00,  00,  00,  00,  00,  00, _
	 00,   00,  00,  00,  00,  00,  00,  00,  00,  00, _
	 00,   00,  00,  00,  00,  00,  00,  00,  96,  97, _
	 00,   00,  00,  00,  00,  00,  00,  00,  00,  00, _
	 00,   00,  00,  00,  00,  00,  00,  00,  00,  00, _
	 00,   00,  00,  99,  00,  00, 100,  00,  00,  00, _
	 00,   00,  00,  00,  00,  00,  00,  00,  00,  00, _
	 00,  102, 103, 104,  00, 105,  00, 106,  00, 107, _
	108,  109, 110, 111,  00,  00,  00,  00,  00,  00, _
	 00,   00,  00,  00,  00,  00,  00,  00,  00,  00, _
	 00,   00,  00,  00,  00,  00,  00,  00,  00,  00, _
	 00,   00,  00,  00,  00,  00,  00,  00,  00,  00, _
	 00,   00,  00,  00,  00,  00,  00,  00 }

function scancode_to_keycode (set as integer, scancode as ushort) as ubyte
	dim keycode as ubyte = 0
	
	select case (set)
		case 0:
			'' normal scancode
			keycode = scancode_table(scancode)
		case 1:
			'' e0-code
			keycode = e0code_table(scancode)
		case 2:
			'' e1-code
			select case (scancode)
				case &h451D:
					keycode = 119
				case else:
					keycode = 0
			end select
		case else
			keycode = 0
	end select
	
	if (keycode = 0) then
		'' TODO: unknown scancode - print warning or something
	end if
	
	return keycode
end function 
