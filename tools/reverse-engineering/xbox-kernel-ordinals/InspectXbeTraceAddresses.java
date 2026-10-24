// Maps observed trace addresses to existing Ghidra function boundaries and direct calls.
// Read-only: does not modify analysis, labels, instructions, or XBE bytes.
// @category XboxRecomp

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.InstructionIterator;
import ghidra.program.model.mem.MemoryAccessException;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.ReferenceIterator;

public class InspectXbeTraceAddresses extends GhidraScript {
	private long readU32(Address address) throws MemoryAccessException {
		long value = 0;
		for (int i = 0; i < 4; i++) {
			value |= ((long) getByte(address.add(i)) & 0xffL) << (8 * i);
		}
		return value;
	}

	@Override
	public void run() throws Exception {
		if (getScriptArgs().length == 0) {
			throw new IllegalArgumentException("Pass one or more hexadecimal virtual addresses.");
		}
		for (String argument : getScriptArgs()) {
			monitor.checkCancelled();
			long value = Long.parseUnsignedLong(argument.replaceFirst("^(0[xX])", ""), 16);
			Address address = toAddr(value);
			println(String.format("\nAddress 0x%08X", value));
			if (!currentProgram.getMemory().contains(address)) {
				println("  not mapped in this Ghidra program");
				continue;
			}
			Function function = currentProgram.getFunctionManager().getFunctionContaining(address);
			if (function == null) {
				println("  no defined function contains this address");
			}
			else {
				println(String.format("  function %s entry=%s body=%s bytes=0x%X",
					function.getName(), function.getEntryPoint(), function.getBody(),
					function.getBody().getNumAddresses()));
				long calls = 0;
				InstructionIterator instructions = currentProgram.getListing().getInstructions(function.getBody(), true);
				while (instructions.hasNext()) {
					monitor.checkCancelled();
					Instruction instruction = instructions.next();
					if (!instruction.getFlowType().isCall()) {
						continue;
					}
					for (Address target : instruction.getFlows()) {
						calls++;
						if (calls <= 40) {
							Function callee = currentProgram.getFunctionManager().getFunctionAt(target);
							String name = callee == null ? "<no function>" : callee.getName();
							println(String.format("    call %s -> %s (%s)", instruction.getAddress(), target, name));
						}
					}
				}
				println("  direct call targets: " + calls + (calls > 40 ? " (first 40 shown)" : ""));
				ReferenceIterator references = currentProgram.getReferenceManager().getReferencesTo(function.getEntryPoint());
				long callers = 0;
				while (references.hasNext()) {
					Reference reference = references.next();
					if (reference.getReferenceType().isCall()) {
						callers++;
						if (callers <= 40) {
							Function caller = currentProgram.getFunctionManager().getFunctionContaining(reference.getFromAddress());
							String name = caller == null ? "<no function>" : caller.getName();
							println(String.format("    caller %s (%s)", reference.getFromAddress(), name));
						}
					}
				}
				println("  direct call references in saved analysis: " + callers + (callers > 40 ? " (first 40 shown)" : ""));
			}
			Instruction instruction = currentProgram.getListing().getInstructionContaining(address);
			if (instruction != null) {
				println("  instruction: " + instruction.getAddress() + "  " + instruction);
			}
		}
		println("Read-only inspection complete; no program data was changed.");
	}
}
