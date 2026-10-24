// Labels decoded Xbox kernel thunk cells with provisional ordinal candidates.
// This script changes Ghidra symbols only; it never patches XBE bytes.
// Candidate names in the adjacent CSV are cross-checked for kernel builds
// 3944/4039, not asserted as exact for Steel Battalion's XDK build 4627.
// @category XboxRecomp

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.symbol.SourceType;
import ghidra.program.model.mem.MemoryAccessException;

import java.io.BufferedReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;

public class AnnotateXboxKernelOrdinals extends GhidraScript {
	private static final long ENTRY_RETAIL_XOR = 0xA8FC57ABL;
	private static final long ENTRY_DEBUG_XOR = 0x94859D4BL;
	private static final long THUNK_RETAIL_XOR = 0x5B6D40B6L;
	private static final long THUNK_DEBUG_XOR = 0xEFB1F152L;
	private static final long U32_MASK = 0xffffffffL;

	private long readU32(Address address) throws MemoryAccessException {
		long value = 0;
		for (int i = 0; i < 4; i++) {
			value |= ((long) getByte(address.add(i)) & 0xffL) << (8 * i);
		}
		return value;
	}

	private boolean mapped(long virtualAddress) {
		try {
			return currentProgram.getMemory().contains(toAddr(virtualAddress));
		}
		catch (Exception e) {
			return false;
		}
	}

	private Map<Integer, String> loadNames(Path csvPath) throws Exception {
		Map<Integer, String> names = new HashMap<>();
		try (BufferedReader reader = Files.newBufferedReader(csvPath, StandardCharsets.UTF_8)) {
			String line;
			boolean first = true;
			while ((line = reader.readLine()) != null) {
				if (first) {
					first = false;
					if (line.startsWith("ordinal,")) {
						continue;
					}
				}
				String[] columns = line.split(",", 2);
				if (columns.length == 2) {
					try {
						names.put(Integer.parseInt(columns[0].trim()), columns[1].trim());
					}
					catch (NumberFormatException ignored) {
						// Ignore malformed rows; unknown names retain ordinal-only labels.
					}
				}
			}
		}
		return names;
	}

	@Override
	public void run() throws Exception {
		if (getScriptArgs().length != 1) {
			throw new IllegalArgumentException("Pass the path to xbox_kernel_ordinals.csv as the single script argument.");
		}

		Address header = currentProgram.getMinAddress();
		if (readU32(header) != 0x48454258L) {
			throw new IllegalStateException("Program minimum address does not contain XBEH; import with ghidra-xbe first.");
		}

		long entryRaw = readU32(header.add(0x128));
		long retailEntry = (entryRaw ^ ENTRY_RETAIL_XOR) & U32_MASK;
		long debugEntry = (entryRaw ^ ENTRY_DEBUG_XOR) & U32_MASK;
		boolean isRetail = mapped(retailEntry);
		if (!isRetail && !mapped(debugEntry)) {
			throw new IllegalStateException("Unable to decode XBE entry point to mapped program memory.");
		}

		long thunkRaw = readU32(header.add(0x158));
		long retailThunk = (thunkRaw ^ THUNK_RETAIL_XOR) & U32_MASK;
		long debugThunk = (thunkRaw ^ THUNK_DEBUG_XOR) & U32_MASK;
		long thunkVA = isRetail ? retailThunk : debugThunk;
		if (!mapped(thunkVA)) {
			thunkVA = isRetail ? debugThunk : retailThunk;
		}
		if (!mapped(thunkVA)) {
			throw new IllegalStateException("Unable to decode kernel thunk table to mapped program memory.");
		}

		Path csvPath = Path.of(getScriptArgs()[0]);
		Map<Integer, String> names = loadNames(csvPath);
		println(String.format("XBE entry point: 0x%08X (%s key)", isRetail ? retailEntry : debugEntry,
			isRetail ? "retail" : "debug"));
		println(String.format("Kernel thunk table: 0x%08X", thunkVA));
		println("Ordinal names are provisional candidates for XDK build 4627.");

		int count = 0;
		for (int i = 0; i < 4096; i++) {
			monitor.checkCancelled();
			Address cell = toAddr(thunkVA + (i * 4L));
			if (!currentProgram.getMemory().contains(cell)) {
				println("Stopped: thunk cell leaves mapped memory at index " + i);
				break;
			}
			long raw = readU32(cell);
			if (raw == 0) {
				println("End of thunk table at index " + i);
				break;
			}
			String label;
			if ((raw & 0x80000000L) != 0) {
				int ordinal = (int) (raw & 0x7fffffffL);
				String candidate = names.getOrDefault(ordinal, String.format("Ordinal_%03d", ordinal));
				label = String.format("XboxKrnl_Ordinal_%03d_Candidate_%s", ordinal, candidate);
			}
			else {
				label = String.format("XboxThunk_NonOrdinal_%03d", i);
			}
			createLabel(cell, label, false, SourceType.USER_DEFINED);
			count++;
		}
		println("Annotated " + count + " kernel thunk cells. No XBE bytes were modified.");
	}
}
