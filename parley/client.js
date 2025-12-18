import { readFile } from "fs/promises";

export class ParleyClient {
  constructor(wasmPath) {
    this.wasmPath = wasmPath;
    this.instance = null;
    this.memory = null;
    this.exports = null;
  }

  async initialize() {
    const wasmBuffer = await readFile(this.wasmPath);

    // Minimal WASI imports - Swift WASM SDK requires these
    const wasiImports = {
      wasi_snapshot_preview1: new Proxy(
        {},
        {
          get: () => () => 0,
        },
      ),
    };

    const { instance } = await WebAssembly.instantiate(wasmBuffer, wasiImports);
    this.instance = instance;
    this.exports = instance.exports;
    this.memory = instance.exports.memory;

    // Initialize if needed
    if (this.exports._initialize) {
      this.exports._initialize();
    } else if (this.exports._start) {
      this.exports._start();
    }
  }

  // Convert string to WASM memory and return pointer + length
  writeString(str) {
    const encoder = new TextEncoder();
    const bytes = encoder.encode(str);
    const ptr = this.exports.alloc(bytes.length);
    const memoryArray = new Uint8Array(this.memory.buffer);
    memoryArray.set(bytes, ptr);
    return { ptr, len: bytes.length };
  }

  // Read string from WASM memory
  readString(ptr, len) {
    const memoryArray = new Uint8Array(this.memory.buffer);
    return new TextDecoder().decode(memoryArray.slice(ptr, ptr + len));
  }

  // Generic function to call WASM JSON endpoints
  async callJSON(functionName, input) {
    const inputJson = JSON.stringify(input);
    const { ptr: inputPtr, len: inputLen } = this.writeString(inputJson);

    try {
      // Call the WASM function
      let result;
      try {
        result = this.exports[functionName](inputPtr, inputLen);
      } catch (wasmError) {
        console.error(`WASM execution error in ${functionName}:`, wasmError);
        throw wasmError;
      }

      // Extract output pointer and length from combined result
      const outPtr = Number(result & 0xffffffffn);
      const outLen = Number(result >> 32n);

      // Read and parse the result
      const outputJson = this.readString(outPtr, outLen);
      const response = JSON.parse(outputJson);

      // Clean up output memory
      this.exports.dealloc(outPtr, outLen);

      // Handle APIResult format
      if (!response.success) {
        throw new Error(response.error || "Unknown error");
      }

      return response.data;
    } finally {
      // Always clean up input memory
      this.exports.dealloc(inputPtr, inputLen);
    }
  }

  // Convenience methods for specific endpoints
  async chart(request) {
    return this.callJSON("chart", request);
  }

  // Simple string-returning functions
  async callString(functionName) {
    const result = this.exports[functionName]();

    // Extract output pointer and length from combined result
    const outPtr = Number(result & 0xffffffffn);
    const outLen = Number(result >> 32n);

    // Read the result
    const output = this.readString(outPtr, outLen);

    // Clean up output memory
    this.exports.dealloc(outPtr, outLen);

    return output;
  }

  async version() {
    return this.callString("version");
  }

  async name() {
    return this.callString("name");
  }
}
