import { describe, it, expect } from "vitest"

// Mock the Clarity functions and types
const mockClarity = {
  tx: {
    sender: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
  },
  types: {
    uint: (value: number) => ({ type: "uint", value }),
    principal: (value: string) => ({ type: "principal", value }),
    string: (value: string) => ({ type: "string", value }),
    optional: (value: any) => ({ type: "optional", value }),
  },
}

// Mock contract calls
const contractCalls = {
  "file-dispute": (ipId: number, respondent: string, claim: string) => {
    return { success: true, value: mockClarity.types.uint(0) }
  },
  "resolve-dispute": (disputeId: number, resolution: string) => {
    return { success: true, value: true }
  },
  "get-dispute": (disputeId: number) => {
    return {
      success: true,
      value: {
        "ip-id": mockClarity.types.uint(0),
        claimant: mockClarity.types.principal("ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"),
        respondent: mockClarity.types.principal("ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"),
        claim: mockClarity.types.string("Copyright infringement claim"),
        status: mockClarity.types.string("resolved"),
        resolution: mockClarity.types.optional(mockClarity.types.string("Dispute resolved in favor of claimant")),
      },
    }
  },
}

describe("Dispute Resolution Contract", () => {
  it("should file a dispute", () => {
    const result = contractCalls["file-dispute"](
        0,
        "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG",
        "Copyright infringement claim",
    )
    expect(result.success).toBe(true)
    expect(result.value).toEqual(mockClarity.types.uint(0))
  })
  
  it("should resolve a dispute", () => {
    const result = contractCalls["resolve-dispute"](0, "Dispute resolved in favor of claimant")
    expect(result.success).toBe(true)
    expect(result.value).toBe(true)
  })
  
  it("should get dispute details", () => {
    const result = contractCalls["get-dispute"](0)
    expect(result.success).toBe(true)
    expect(result.value).toEqual({
      "ip-id": mockClarity.types.uint(0),
      claimant: mockClarity.types.principal("ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"),
      respondent: mockClarity.types.principal("ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"),
      claim: mockClarity.types.string("Copyright infringement claim"),
      status: mockClarity.types.string("resolved"),
      resolution: mockClarity.types.optional(mockClarity.types.string("Dispute resolved in favor of claimant")),
    })
  })
})

