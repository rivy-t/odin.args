package main

// ref: [JoelOnSoftware ~ Minimum knowledge of Unicode](https://www.joelonsoftware.com/2003/10/08/the-absolute-minimum-every-software-developer-absolutely-positively-must-know-about-unicode-and-character-sets-no-excuses) @@ <https://archive.is/2UVWT>
// ref: [The Tragedy of UCS-2](https://unascribed.com/b/2019-08-02-the-tragedy-of-ucs2.html) @@ <https://archive.is/x4SxI>
// ref: [SO ~ Which Unicode (with history)?](https://stackoverflow.com/questions/3473295/utf-8-or-utf-16-or-utf-32-or-ucs-2) @@ <>
// ref: [UTF-8 Everywhere](https://utf8everywhere.org) @@ <https://archive.is/7b6ga>
// ref: [Unicode in MS Windows](https://en.wikipedia.org/wiki/Unicode_in_Microsoft_Windows) @@ <https://archive.is/Mmf48>
// ref: [JavaScript character encoding](https://mathiasbynens.be/notes/javascript-encoding) @@ <https://archive.is/yNnof>
// ref: [MSDN ~ Unicode and MBCS support](https://learn.microsoft.com/en-us/cpp/atl-mfc-shared/unicode-and-multibyte-character-set-mbcs-support) @@ <https://archive.is/Iy2Js>
// ref: [MSDN ~ string conversions](https://learn.microsoft.com/en-US/sql/relational-databases/collations/collation-and-unicode-support#utf8) @@ <https://archive.is/hZvZx>
// ref: [MSDN ~ LPCSTR](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/f8d4fe46-6be8-44c9-8823-615a21d17a61) @@ <https://archive.is/AduZv>)
// ref: [WTF-8 encoding](https://simonsapin.github.io/wtf-8) @@ <https://archive.is/irzit>
// ref: [MSDN ~ String type conversions](https://learn.microsoft.com/en-us/cpp/text/how-to-convert-between-various-string-types) @@ <https://archive.is/lKYhP>

// ref: [MSDN ~ GetCommandLine](https://learn.microsoft.com/en-us/windows/win32/api/processenv/nf-processenv-getcommandlinew) @@ <https://archive.is/3ApUT>
// ref: [MSDN ~ CommandLineToARGVW](https://learn.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-commandlinetoargvw) @@ <https://archive.is/7Cz92>

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:strings"

import WinOS "core:sys/windows"


Platform_Error :: enum u32 {
	None = 0,
}

Conversion_Error :: union #shared_nil {
	runtime.Allocator_Error,
	Platform_Error,
}

// WCHAR == wchar_t == u16
// WSTR == wstring == [^]WCHAR ('multi-pointer' to array of WCHAR; 'multi-pointer' is used to ease FFI)
// CWSTR == NUL-terminated WSTR

CWSTR_to_UTF8 :: proc(
	wstr: WinOS.LPCWSTR,
	allocator := context.temp_allocator,
) -> (
	result: string,
	err: Conversion_Error,
) {
	return WSTR_to_UTF8(wstr, -1, allocator)
}

WSTR_to_UTF8 :: proc(
	wstr: WinOS.LPWSTR,
	len: int,
	allocator := context.temp_allocator,
) -> (
	result: string,
	err: Conversion_Error,
) {
	context.allocator = allocator

	if len == 0 {
		return "", nil
	}

	buffer_byte_size := WinOS.WideCharToMultiByte(
		WinOS.CP_UTF8, // CodePage
		WinOS.WC_ERR_INVALID_CHARS, // dwFlags
		wstr, // lpWideCharStr
		i32(len) if len > 0 else -1, // cchWideChar
		nil, // lpMultiByteStr [out]
		0, // cbMultiByte
		nil, // lpDefaultChar
		nil, // lpUsedDefaultChar
	)
	if buffer_byte_size == 0 {
		return "", Platform_Error(WinOS.GetLastError())
	}

	utf8 := make([]byte, buffer_byte_size) or_return

	bytes_copied := WinOS.WideCharToMultiByte(
		WinOS.CP_UTF8, // CodePage
		WinOS.WC_ERR_INVALID_CHARS, // dwFlags
		wstr, // lpWideCharStr
		i32(len) if len > 0 else -1, // cchWideChar
		raw_data(utf8), // lpMultiByteStr [out]
		buffer_byte_size, // cbMultiByte
		nil, // lpDefaultChar
		nil, // lpUsedDefaultChar
	)
	if bytes_copied == 0 {
		delete(utf8, context.allocator)
		return "", Platform_Error(WinOS.GetLastError())
	}

	slice_end := buffer_byte_size
	if (len < 0) && (utf8[buffer_byte_size - 1] == 0) {
		// for indeterminate input length, don't include the terminating NUL
		slice_end -= 1
	}

	return string(utf8[:slice_end]), runtime.Allocator_Error{}
}

main :: proc() {
	exit_value := 0

	// s := "hello\x00"
	// fmt.printf("[%d]`%s`\n", strings.rune_count(s), s)

	// cmd_line_ptr: WinOS.LPCWSTR = WinOS.GetCommandLineW() // pointer to null-terminated WCHAR string array
	// cmd_line, _ := WinOS.wstring_to_utf8(cmd_line_ptr, -1)
	// cmd_line, err := WinOS.wstring_to_utf8(WinOS.GetCommandLineW(), -1)
	p_cmd_line := WinOS.GetCommandLineW()

	MAX_CMD_LINE_LEN := 64 * 1024 // defensive avoidance of infinite runaways if CommandLine is not NUL-terminated
	cmd_line_length := 0
	for i := 0; i < MAX_CMD_LINE_LEN; i += 1 {if p_cmd_line[i] == 0 {cmd_line_length = i;break}}
	fmt.printf("[%d]\n", cmd_line_length)

	// cmd_line, err := WSTR_to_UTF8(WinOS.GetCommandLineW(), cmd_line_length + 0)
	cmd_line, err := CWSTR_to_UTF8(WinOS.GetCommandLineW())
	if err != nil {
		fmt.println(err)
		os.exit(1)
	}
	fmt.printf("[%d]`%s`\n", strings.rune_count(cmd_line), cmd_line)

	// os.args is a []string
	fmt.println(os.args[0]) // executable name
	fmt.println(os.args[1:]) // the rest of the arguments

	os.exit(exit_value)
}
