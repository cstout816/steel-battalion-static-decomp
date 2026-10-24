// Read-only inventory of an already analyzed XBE project.
// @category XboxRecomp

import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionIterator;
import ghidra.program.model.mem.MemoryBlock;

public class SummarizeXbeAnalysis extends GhidraScript {
	@Override
	public void run() throws Exception {
		println("Program: " + currentProgram.getName());
		println("Language: " + currentProgram.getLanguageID());
		println("Address range: " + currentProgram.getMinAddress() + " .. " + currentProgram.getMaxAddress());
		println("Memory blocks:");
		long totalBlockBytes = 0;
		int blockCount = 0;
		for (MemoryBlock block : currentProgram.getMemory().getBlocks()) {
			monitor.checkCancelled();
			long size = block.getSize();
			totalBlockBytes += size;
			blockCount++;
			println(String.format("  %s %s..%s size=0x%X R=%s W=%s X=%s initialized=%s",
				block.getName(), block.getStart(), block.getEnd(), size, block.isRead(), block.isWrite(),
				block.isExecute(), block.isInitialized()));
		}
		println(String.format("Memory block total: %d blocks, 0x%X bytes", blockCount, totalBlockBytes));

		long functionCount = 0;
		long totalBodyBytes = 0;
		long minBodyBytes = Long.MAX_VALUE;
		long maxBodyBytes = 0;
		FunctionIterator functions = currentProgram.getFunctionManager().getFunctions(true);
		while (functions.hasNext()) {
			monitor.checkCancelled();
			Function function = functions.next();
			long bodyBytes = function.getBody().getNumAddresses();
			functionCount++;
			totalBodyBytes += bodyBytes;
			minBodyBytes = Math.min(minBodyBytes, bodyBytes);
			maxBodyBytes = Math.max(maxBodyBytes, bodyBytes);
		}
		println("Defined functions: " + functionCount);
		if (functionCount > 0) {
			println(String.format("Function body address bytes: total=0x%X min=0x%X max=0x%X",
				totalBodyBytes, minBodyBytes, maxBodyBytes));
		}
		println("No analysis, memory, symbols, or instructions were changed.");
	}
}
