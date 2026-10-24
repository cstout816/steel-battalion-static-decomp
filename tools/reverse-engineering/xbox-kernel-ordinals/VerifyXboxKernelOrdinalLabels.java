// Read-only verification of ordinal candidate labels in the current Ghidra program.
// @category XboxRecomp

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.symbol.Symbol;

import ghidra.program.model.mem.MemoryAccessException;

public class VerifyXboxKernelOrdinalLabels extends GhidraScript {
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

	@Override
	public void run() throws Exception {
		Address header = currentProgram.getMinAddress();
		if (readU32(header) != 0x48454258L) {
			throw new IllegalStateException("Program minimum address is not an XBEH header.");
		}
		long entryRaw = readU32(header.add(0x128));
		long retailEntry = (entryRaw ^ ENTRY_RETAIL_XOR) & U32_MASK;
		long debugEntry = (entryRaw ^ ENTRY_DEBUG_XOR) & U32_MASK;
		boolean isRetail = mapped(retailEntry);
		if (!isRetail && !mapped(debugEntry)) {
			throw new IllegalStateException("Unable to decode the XBE entry point.");
		}
		long thunkRaw = readU32(header.add(0x158));
		long retailThunk = (thunkRaw ^ THUNK_RETAIL_XOR) & U32_MASK;
		long debugThunk = (thunkRaw ^ THUNK_DEBUG_XOR) & U32_MASK;
		long thunkVA = isRetail ? retailThunk : debugThunk;
		if (!mapped(thunkVA)) {
			thunkVA = isRetail ? debugThunk : retailThunk;
		}
		if (!mapped(thunkVA)) {
			throw new IllegalStateException("Unable to decode the XBE thunk table.");
		}

		int expected = 0;
		int found = 0;
		for (int i = 0; i < 4096; i++) {
			monitor.checkCancelled();
			Address cell = toAddr(thunkVA + (i * 4L));
			if (!currentProgram.getMemory().contains(cell)) {
				break;
			}
			long raw = readU32(cell);
			if (raw == 0) {
				break;
			}
			if ((raw & 0x80000000L) == 0) {
				continue;
			}
			expected++;
			boolean labeled = false;
			for (Symbol symbol : currentProgram.getSymbolTable().getSymbols(cell)) {
				if (symbol.getName().startsWith("XboxKrnl_Ordinal_")) {
					labeled = true;
					break;
				}
			}
			if (labeled) {
				found++;
			}
			else {
				println(String.format("Missing ordinal label at thunk cell 0x%08X", thunkVA + i * 4L));
			}
		}
		println(String.format("Verified %d of %d ordinal thunk labels.", found, expected));
		if (found != expected || expected != 123) {
			throw new IllegalStateException("Ordinal label count did not match the expected 123 imports.");
		}
	}
}
