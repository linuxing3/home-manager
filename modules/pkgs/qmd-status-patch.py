from pathlib import Path

path = Path("src/cli/qmd.ts")
text = path.read_text()
old = """  // Device / GPU info
  try {
    const llm = getDefaultLlamaCpp();
    const device = await llm.getDeviceInfo();
    console.log(`\\n${c.bold}Device${c.reset}`);
    if (device.gpu) {
      console.log(`  GPU:      ${c.green}${device.gpu}${c.reset} (offloading: ${device.gpuOffloading ? 'yes' : 'no'})`);
      if (device.gpuDevices.length > 0) {
        // Deduplicate and count GPUs
        const counts = new Map<string, number>();
        for (const name of device.gpuDevices) {
          counts.set(name, (counts.get(name) || 0) + 1);
        }
        const deviceStr = Array.from(counts.entries())
          .map(([name, count]) => count > 1 ? `${count}× ${name}` : name)
          .join(', ');
        console.log(`  Devices:  ${deviceStr}`);
      }
      if (device.vram) {
        console.log(`  VRAM:     ${formatBytes(device.vram.free)} free / ${formatBytes(device.vram.total)} total`);
      }
    } else {
      console.log(`  GPU:      ${c.yellow}none${c.reset} (running on CPU — models will be slow)`);
      console.log(`  ${c.dim}Tip: Install CUDA, Vulkan, or Metal support for GPU acceleration.${c.reset}`);
    }
    console.log(`  CPU:      ${device.cpuCores} math cores`);
  } catch {
    // Don't fail status if LLM init fails
  }
"""
new = """  // Device / GPU info
  try {
    const { getLlama, LlamaLogLevel } = await import("node-llama-cpp");
    const llama = await getLlama({
      gpu: false,
      build: "never",
      progressLogs: false,
      logLevel: LlamaLogLevel.disabled,
      logger: () => {},
    });
    try {
      let vram: { total: number; used: number; free: number } | undefined;
      const gpuDevices = await llama.getGpuDeviceNames();
      if (llama.gpu) {
        try {
          const state = await llama.getVramState();
          vram = { total: state.total, used: state.used, free: state.free };
        } catch { /* no vram info */ }
      }
      const device = {
        gpu: llama.gpu,
        gpuOffloading: llama.supportsGpuOffloading,
        gpuDevices,
        vram,
        cpuCores: llama.cpuMathCores,
      };
      console.log(`\\n${c.bold}Device${c.reset}`);
      if (device.gpu) {
        console.log(`  GPU:      ${c.green}${device.gpu}${c.reset} (offloading: ${device.gpuOffloading ? 'yes' : 'no'})`);
        if (device.gpuDevices.length > 0) {
          // Deduplicate and count GPUs
          const counts = new Map<string, number>();
          for (const name of device.gpuDevices) {
            counts.set(name, (counts.get(name) || 0) + 1);
          }
          const deviceStr = Array.from(counts.entries())
            .map(([name, count]) => count > 1 ? `${count}× ${name}` : name)
            .join(', ');
          console.log(`  Devices:  ${deviceStr}`);
        }
        if (device.vram) {
          console.log(`  VRAM:     ${formatBytes(device.vram.free)} free / ${formatBytes(device.vram.total)} total`);
        }
      } else {
        console.log(`  GPU:      ${c.yellow}none${c.reset} (running on CPU — models will be slow)`);
        console.log(`  ${c.dim}Tip: Install CUDA, Vulkan, or Metal support for GPU acceleration.${c.reset}`);
      }
      console.log(`  CPU:      ${device.cpuCores} math cores`);
    } finally {
      void llama.dispose().catch(() => {});
    }
  } catch {
    // Don't fail status if LLM init fails
  }
"""

if old not in text:
    raise SystemExit("qmd status device block not found")

path.write_text(text.replace(old, new, 1))
