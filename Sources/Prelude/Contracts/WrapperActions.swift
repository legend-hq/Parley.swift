@preconcurrency import SwiftNumber
@preconcurrency import Eth
import Foundation

public enum WrapperActions {
    public static let creationCode: Hex = "0x608060405234601c57600e6020565b61101361002b823961101390f35b6026565b60405190565b5f80fdfe60806040526004361015610013575b6103f9565b61001d5f356100bb565b80628342b6146100b657806315a05a4e146100b15780631e64918f146100ac57806329793f7d146100a757806334ce5dc4146100a257806348ab02c41461009d5780635869dba814610098578063a91a3f1014610093578063b781a58a1461008e5763e3d45a830361000e576103c5565b610357565b610324565b6102f0565b6102bc565b61025c565b610228565b6101f5565b6101a3565b61016f565b60e01c90565b60405190565b5f80fd5b5f80fd5b73ffffffffffffffffffffffffffffffffffffffff1690565b6100f1906100cf565b90565b6100fd816100e8565b0361010457565b5f80fd5b90503590610115826100f4565b565b90565b61012381610117565b0361012a57565b5f80fd5b9050359061013b8261011a565b565b91906040838203126101655780610159610162925f8601610108565b9360200161012e565b90565b6100cb565b5f0190565b3461019e5761018861018236600461013d565b90610555565b6101906100c1565b8061019a8161016a565b0390f35b6100c7565b346101d2576101bc6101b636600461013d565b9061066c565b6101c46100c1565b806101ce8161016a565b0390f35b6100c7565b906020828203126101f0576101ed915f01610108565b90565b6100cb565b346102235761020d6102083660046101d7565b610753565b6102156100c1565b8061021f8161016a565b0390f35b6100c7565b346102575761024161023b36600461013d565b90610884565b6102496100c1565b806102538161016a565b0390f35b6100c7565b3461028a5761027461026f3660046101d7565b610914565b61027c6100c1565b806102868161016a565b0390f35b6100c7565b91906040838203126102b757806102ab6102b4925f8601610108565b93602001610108565b90565b6100cb565b346102eb576102d56102cf36600461028f565b90610abc565b6102dd6100c1565b806102e78161016a565b0390f35b6100c7565b3461031f5761030961030336600461013d565b90610c75565b6103116100c1565b8061031b8161016a565b0390f35b6100c7565b346103525761033c6103373660046101d7565b610d05565b6103446100c1565b8061034e8161016a565b0390f35b6100c7565b346103865761037061036a36600461013d565b90610dc0565b6103786100c1565b806103828161016a565b0390f35b6100c7565b90916060828403126103c0576103bd6103a6845f8501610108565b936103b48160208601610108565b9360400161012e565b90565b6100cb565b346103f4576103de6103d836600461038b565b91610f0a565b6103e66100c1565b806103f08161016a565b0390f35b6100c7565b5f80fd5b90565b61041461040f610419926100cf565b6103fd565b6100cf565b90565b61042590610400565b90565b6104319061041c565b90565b61043d90610400565b90565b61044990610434565b90565b6104559061041c565b90565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52601160045260245ffd5b61049461049a91939293610117565b92610117565b82039182116104a557565b610458565b5f80fd5b601f801991011690565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52604160045260245ffd5b906104ef906104ae565b810190811067ffffffffffffffff82111761050957604052565b6104b8565b60e01b90565b5f91031261051e57565b6100cb565b61052c90610117565b9052565b9190610543905f60208501940190610523565b565b61054d6100c1565b3d5f823e3d90fd5b9061055f30610428565b31918261057461056e84610117565b91610117565b1061057f575b505050565b61059361058e61059f92610440565b61044c565b92632e1a7d4d92610485565b823b15610616576105cf926105c45f80946105b86100c1565b9687958694859361050e565b835260048301610530565b03925af18015610611576105e5575b808061057a565b610604905f3d811161060a575b6105fc81836104e5565b810190610514565b5f6105de565b503d6105f2565b610545565b6104aa565b61062490610400565b90565b6106309061061b565b90565b61063c9061041c565b90565b9050519061064c8261011a565b565b9060208282031261066757610664915f0161063f565b90565b6100cb565b6106ab9161068361067e602093610627565b610633565b6106a05f63de0e9a3e6106946100c1565b9687958694859361050e565b835260048301610530565b03925af180156106e9576106bd575b50565b6106dd9060203d81116106e2575b6106d581836104e5565b81019061064e565b6106ba565b503d6106cb565b610545565b6106f790610400565b90565b610703906106ee565b90565b61070f9061041c565b90565b61071b906100e8565b9052565b9190610732905f60208501940190610712565b565b90565b61074b61074661075092610734565b6103fd565b610117565b90565b61079b6020610769610764846106fa565b610706565b6370a082319061079061077b30610428565b926107846100c1565b9586948593849361050e565b83526004830161071f565b03915afa90811561087f575f91610851575b5090816107c26107bc5f610737565b91610117565b116107cc575b5050565b61080b916107e36107de602093610627565b610633565b6108005f63de0e9a3e6107f46100c1565b9687958694859361050e565b835260048301610530565b03925af1801561084c57610820575b806107c8565b6108409060203d8111610845575b61083881836104e5565b81019061064e565b61081a565b503d61082e565b610545565b610872915060203d8111610878575b61086a81836104e5565b81019061064e565b5f6107ad565b503d610860565b610545565b61089061089591610440565b61044c565b9063d0e30db0909190813b1561090f575f916108bd916108b36100c1565b948593849261050e565b8252816108cc6004820161016a565b03925af1801561090a576108de575b50565b6108fd905f3d8111610903575b6108f581836104e5565b810190610514565b5f6108db565b503d6108eb565b610545565b6104aa565b61095c602061092a610925846106fa565b610706565b6370a082319061095161093c30610428565b926109456100c1565b9586948593849361050e565b83526004830161071f565b03915afa908115610a4e575f91610a20575b50908161098361097d5f610737565b91610117565b1161098d575b5050565b61099961099e91610440565b61044c565b90632e1a7d4d90823b15610a1b576109d5926109ca5f80946109be6100c1565b9687958694859361050e565b835260048301610530565b03925af18015610a16576109ea575b80610989565b610a09905f3d8111610a0f575b610a0181836104e5565b810190610514565b5f6109e4565b503d6109f7565b610545565b6104aa565b610a41915060203d8111610a47575b610a3981836104e5565b81019061064e565b5f61096e565b503d610a2f565b610545565b151590565b610a6181610a53565b03610a6857565b5f80fd5b90505190610a7982610a58565b565b90602082820312610a9457610a91915f01610a6c565b90565b6100cb565b916020610aba929493610ab360408201965f830190610712565b0190610523565b565b610b046020610ad2610acd856106fa565b610706565b6370a0823190610af9610ae430610428565b92610aed6100c1565b9586948593849361050e565b83526004830161071f565b03915afa908115610c70575f91610c42575b509182610b2b610b255f610737565b91610117565b11610b36575b505050565b610b42610b47916106fa565b610706565b91602063095ea7b3938390610b6f5f8597610b7a610b636100c1565b998a968795869461050e565b845260048401610a99565b03925af1928315610c3d57610b9e602093610ba392610bcb96610c12575b50610627565b610633565b610bc05f63ea598cb0610bb46100c1565b9687958694859361050e565b835260048301610530565b03925af18015610c0d57610be1575b8080610b31565b610c019060203d8111610c06575b610bf981836104e5565b81019061064e565b610bda565b503d610bef565b610545565b610c3190863d8111610c36575b610c2981836104e5565b810190610a7b565b610b98565b503d610c1f565b610545565b610c63915060203d8111610c69575b610c5b81836104e5565b81019061064e565b5f610b16565b503d610c51565b610545565b610c81610c8691610440565b61044c565b90632e1a7d4d90823b15610d0057610cbd92610cb25f8094610ca66100c1565b9687958694859361050e565b835260048301610530565b03925af18015610cfb57610ccf575b50565b610cee905f3d8111610cf4575b610ce681836104e5565b810190610514565b5f610ccc565b503d610cdc565b610545565b6104aa565b610d0e30610428565b319081610d23610d1d5f610737565b91610117565b11610d2d575b5050565b610d39610d3e91610440565b61044c565b9063d0e30db0909190813b15610dbb575f91610d6691610d5c6100c1565b948593849261050e565b825281610d756004820161016a565b03925af18015610db657610d8a575b80610d29565b610da9905f3d8111610daf575b610da181836104e5565b810190610514565b5f610d84565b503d610d97565b610545565b6104aa565b90610e096020610dd7610dd2856106fa565b610706565b6370a0823190610dfe610de930610428565b92610df26100c1565b9586948593849361050e565b83526004830161071f565b03915afa908115610f05575f91610ed7575b509182610e30610e2a84610117565b91610117565b10610e3b575b505050565b610e4f610e4a610e5b92610440565b61044c565b9263d0e30db092610485565b9190813b15610ed2575f91610e7c91610e726100c1565b948593849261050e565b825281610e8b6004820161016a565b03925af18015610ecd57610ea1575b8080610e36565b610ec0905f3d8111610ec6575b610eb881836104e5565b810190610514565b5f610e9a565b503d610eae565b610545565b6104aa565b610ef8915060203d8111610efe575b610ef081836104e5565b81019061064e565b5f610e1b565b503d610ee6565b610545565b90610f17610f1c916106fa565b610706565b91602063095ea7b3938390610f445f8597610f4f610f386100c1565b998a968795869461050e565b845260048401610a99565b03925af192831561100e57610f73602093610f7892610fa096610fe3575b50610627565b610633565b610f955f63ea598cb0610f896100c1565b9687958694859361050e565b835260048301610530565b03925af18015610fde57610fb2575b50565b610fd29060203d8111610fd7575b610fca81836104e5565b81019061064e565b610faf565b503d610fc0565b610545565b61100290863d8111611007575b610ffa81836104e5565b810190610a7b565b610f6d565b503d610ff0565b61054556"
    public static let runtimeCode: Hex = "0x60806040526004361015610013575b6103f9565b61001d5f356100bb565b80628342b6146100b657806315a05a4e146100b15780631e64918f146100ac57806329793f7d146100a757806334ce5dc4146100a257806348ab02c41461009d5780635869dba814610098578063a91a3f1014610093578063b781a58a1461008e5763e3d45a830361000e576103c5565b610357565b610324565b6102f0565b6102bc565b61025c565b610228565b6101f5565b6101a3565b61016f565b60e01c90565b60405190565b5f80fd5b5f80fd5b73ffffffffffffffffffffffffffffffffffffffff1690565b6100f1906100cf565b90565b6100fd816100e8565b0361010457565b5f80fd5b90503590610115826100f4565b565b90565b61012381610117565b0361012a57565b5f80fd5b9050359061013b8261011a565b565b91906040838203126101655780610159610162925f8601610108565b9360200161012e565b90565b6100cb565b5f0190565b3461019e5761018861018236600461013d565b90610555565b6101906100c1565b8061019a8161016a565b0390f35b6100c7565b346101d2576101bc6101b636600461013d565b9061066c565b6101c46100c1565b806101ce8161016a565b0390f35b6100c7565b906020828203126101f0576101ed915f01610108565b90565b6100cb565b346102235761020d6102083660046101d7565b610753565b6102156100c1565b8061021f8161016a565b0390f35b6100c7565b346102575761024161023b36600461013d565b90610884565b6102496100c1565b806102538161016a565b0390f35b6100c7565b3461028a5761027461026f3660046101d7565b610914565b61027c6100c1565b806102868161016a565b0390f35b6100c7565b91906040838203126102b757806102ab6102b4925f8601610108565b93602001610108565b90565b6100cb565b346102eb576102d56102cf36600461028f565b90610abc565b6102dd6100c1565b806102e78161016a565b0390f35b6100c7565b3461031f5761030961030336600461013d565b90610c75565b6103116100c1565b8061031b8161016a565b0390f35b6100c7565b346103525761033c6103373660046101d7565b610d05565b6103446100c1565b8061034e8161016a565b0390f35b6100c7565b346103865761037061036a36600461013d565b90610dc0565b6103786100c1565b806103828161016a565b0390f35b6100c7565b90916060828403126103c0576103bd6103a6845f8501610108565b936103b48160208601610108565b9360400161012e565b90565b6100cb565b346103f4576103de6103d836600461038b565b91610f0a565b6103e66100c1565b806103f08161016a565b0390f35b6100c7565b5f80fd5b90565b61041461040f610419926100cf565b6103fd565b6100cf565b90565b61042590610400565b90565b6104319061041c565b90565b61043d90610400565b90565b61044990610434565b90565b6104559061041c565b90565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52601160045260245ffd5b61049461049a91939293610117565b92610117565b82039182116104a557565b610458565b5f80fd5b601f801991011690565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52604160045260245ffd5b906104ef906104ae565b810190811067ffffffffffffffff82111761050957604052565b6104b8565b60e01b90565b5f91031261051e57565b6100cb565b61052c90610117565b9052565b9190610543905f60208501940190610523565b565b61054d6100c1565b3d5f823e3d90fd5b9061055f30610428565b31918261057461056e84610117565b91610117565b1061057f575b505050565b61059361058e61059f92610440565b61044c565b92632e1a7d4d92610485565b823b15610616576105cf926105c45f80946105b86100c1565b9687958694859361050e565b835260048301610530565b03925af18015610611576105e5575b808061057a565b610604905f3d811161060a575b6105fc81836104e5565b810190610514565b5f6105de565b503d6105f2565b610545565b6104aa565b61062490610400565b90565b6106309061061b565b90565b61063c9061041c565b90565b9050519061064c8261011a565b565b9060208282031261066757610664915f0161063f565b90565b6100cb565b6106ab9161068361067e602093610627565b610633565b6106a05f63de0e9a3e6106946100c1565b9687958694859361050e565b835260048301610530565b03925af180156106e9576106bd575b50565b6106dd9060203d81116106e2575b6106d581836104e5565b81019061064e565b6106ba565b503d6106cb565b610545565b6106f790610400565b90565b610703906106ee565b90565b61070f9061041c565b90565b61071b906100e8565b9052565b9190610732905f60208501940190610712565b565b90565b61074b61074661075092610734565b6103fd565b610117565b90565b61079b6020610769610764846106fa565b610706565b6370a082319061079061077b30610428565b926107846100c1565b9586948593849361050e565b83526004830161071f565b03915afa90811561087f575f91610851575b5090816107c26107bc5f610737565b91610117565b116107cc575b5050565b61080b916107e36107de602093610627565b610633565b6108005f63de0e9a3e6107f46100c1565b9687958694859361050e565b835260048301610530565b03925af1801561084c57610820575b806107c8565b6108409060203d8111610845575b61083881836104e5565b81019061064e565b61081a565b503d61082e565b610545565b610872915060203d8111610878575b61086a81836104e5565b81019061064e565b5f6107ad565b503d610860565b610545565b61089061089591610440565b61044c565b9063d0e30db0909190813b1561090f575f916108bd916108b36100c1565b948593849261050e565b8252816108cc6004820161016a565b03925af1801561090a576108de575b50565b6108fd905f3d8111610903575b6108f581836104e5565b810190610514565b5f6108db565b503d6108eb565b610545565b6104aa565b61095c602061092a610925846106fa565b610706565b6370a082319061095161093c30610428565b926109456100c1565b9586948593849361050e565b83526004830161071f565b03915afa908115610a4e575f91610a20575b50908161098361097d5f610737565b91610117565b1161098d575b5050565b61099961099e91610440565b61044c565b90632e1a7d4d90823b15610a1b576109d5926109ca5f80946109be6100c1565b9687958694859361050e565b835260048301610530565b03925af18015610a16576109ea575b80610989565b610a09905f3d8111610a0f575b610a0181836104e5565b810190610514565b5f6109e4565b503d6109f7565b610545565b6104aa565b610a41915060203d8111610a47575b610a3981836104e5565b81019061064e565b5f61096e565b503d610a2f565b610545565b151590565b610a6181610a53565b03610a6857565b5f80fd5b90505190610a7982610a58565b565b90602082820312610a9457610a91915f01610a6c565b90565b6100cb565b916020610aba929493610ab360408201965f830190610712565b0190610523565b565b610b046020610ad2610acd856106fa565b610706565b6370a0823190610af9610ae430610428565b92610aed6100c1565b9586948593849361050e565b83526004830161071f565b03915afa908115610c70575f91610c42575b509182610b2b610b255f610737565b91610117565b11610b36575b505050565b610b42610b47916106fa565b610706565b91602063095ea7b3938390610b6f5f8597610b7a610b636100c1565b998a968795869461050e565b845260048401610a99565b03925af1928315610c3d57610b9e602093610ba392610bcb96610c12575b50610627565b610633565b610bc05f63ea598cb0610bb46100c1565b9687958694859361050e565b835260048301610530565b03925af18015610c0d57610be1575b8080610b31565b610c019060203d8111610c06575b610bf981836104e5565b81019061064e565b610bda565b503d610bef565b610545565b610c3190863d8111610c36575b610c2981836104e5565b810190610a7b565b610b98565b503d610c1f565b610545565b610c63915060203d8111610c69575b610c5b81836104e5565b81019061064e565b5f610b16565b503d610c51565b610545565b610c81610c8691610440565b61044c565b90632e1a7d4d90823b15610d0057610cbd92610cb25f8094610ca66100c1565b9687958694859361050e565b835260048301610530565b03925af18015610cfb57610ccf575b50565b610cee905f3d8111610cf4575b610ce681836104e5565b810190610514565b5f610ccc565b503d610cdc565b610545565b6104aa565b610d0e30610428565b319081610d23610d1d5f610737565b91610117565b11610d2d575b5050565b610d39610d3e91610440565b61044c565b9063d0e30db0909190813b15610dbb575f91610d6691610d5c6100c1565b948593849261050e565b825281610d756004820161016a565b03925af18015610db657610d8a575b80610d29565b610da9905f3d8111610daf575b610da181836104e5565b810190610514565b5f610d84565b503d610d97565b610545565b6104aa565b90610e096020610dd7610dd2856106fa565b610706565b6370a0823190610dfe610de930610428565b92610df26100c1565b9586948593849361050e565b83526004830161071f565b03915afa908115610f05575f91610ed7575b509182610e30610e2a84610117565b91610117565b10610e3b575b505050565b610e4f610e4a610e5b92610440565b61044c565b9263d0e30db092610485565b9190813b15610ed2575f91610e7c91610e726100c1565b948593849261050e565b825281610e8b6004820161016a565b03925af18015610ecd57610ea1575b8080610e36565b610ec0905f3d8111610ec6575b610eb881836104e5565b810190610514565b5f610e9a565b503d610eae565b610545565b6104aa565b610ef8915060203d8111610efe575b610ef081836104e5565b81019061064e565b5f610e1b565b503d610ee6565b610545565b90610f17610f1c916106fa565b610706565b91602063095ea7b3938390610f445f8597610f4f610f386100c1565b998a968795869461050e565b845260048401610a99565b03925af192831561100e57610f73602093610f7892610fa096610fe3575b50610627565b610633565b610f955f63ea598cb0610f896100c1565b9687958694859361050e565b835260048301610530565b03925af18015610fde57610fb2575b50565b610fd29060203d8111610fd7575b610fca81836104e5565b81019061064e565b610faf565b503d610fc0565b610545565b61100290863d8111611007575b610ffa81836104e5565b810190610a7b565b610f6d565b503d610ff0565b61054556"


    public enum RevertReason : Equatable, Error {
        case unknownRevert(String, String)
    }
    public static func rewrapError(_ error: ABI.Function, value: ABI.Value) -> RevertReason {
        switch (error, value) {
        case let (e, v):
            return .unknownRevert(e.name, String(describing: v))
        }
    }
    public static let errors: [ABI.Function] = []
    public static let functions: [ABI.Function] = [unwrapAllLidoWstETHFn, unwrapAllWETHFn, unwrapLidoWstETHFn, unwrapWETHFn, unwrapWETHUpToFn, wrapAllETHFn, wrapAllLidoStETHFn, wrapETHFn, wrapETHUpToFn, wrapLidoStETHFn]
    public static let unwrapAllLidoWstETHFn = ABI.Function(
            name: "unwrapAllLidoWstETH",
            inputs: [.address],
            outputs: []
    )

    public static func unwrapAllLidoWstETH(wstETH: EthAddress, withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<(), RevertReason> {
            do {
                let query = try unwrapAllLidoWstETHFn.encoded(with: [.address(wstETH)])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try unwrapAllLidoWstETHFn.decode(output: result)

                switch decoded {
                case  .tuple0:
                    return .success(())
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, unwrapAllLidoWstETHFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func unwrapAllLidoWstETHDecode(input: Hex) throws -> (EthAddress) {
        let decodedInput = try unwrapAllLidoWstETHFn.decodeInput(input: input)
        switch decodedInput {
        case let .tuple1(.address(wstETH)):
            return  (wstETH)
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, unwrapAllLidoWstETHFn.inputTuple)
        }
    }

    public static let unwrapAllWETHFn = ABI.Function(
            name: "unwrapAllWETH",
            inputs: [.address],
            outputs: []
    )

    public static func unwrapAllWETH(weth: EthAddress, withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<(), RevertReason> {
            do {
                let query = try unwrapAllWETHFn.encoded(with: [.address(weth)])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try unwrapAllWETHFn.decode(output: result)

                switch decoded {
                case  .tuple0:
                    return .success(())
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, unwrapAllWETHFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func unwrapAllWETHDecode(input: Hex) throws -> (EthAddress) {
        let decodedInput = try unwrapAllWETHFn.decodeInput(input: input)
        switch decodedInput {
        case let .tuple1(.address(weth)):
            return  (weth)
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, unwrapAllWETHFn.inputTuple)
        }
    }

    public static let unwrapLidoWstETHFn = ABI.Function(
            name: "unwrapLidoWstETH",
            inputs: [.address, .uint256],
            outputs: []
    )

    public static func unwrapLidoWstETH(wstETH: EthAddress, amount: Number, withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<(), RevertReason> {
            do {
                let query = try unwrapLidoWstETHFn.encoded(with: [.address(wstETH), .uint256(amount)])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try unwrapLidoWstETHFn.decode(output: result)

                switch decoded {
                case  .tuple0:
                    return .success(())
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, unwrapLidoWstETHFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func unwrapLidoWstETHDecode(input: Hex) throws -> (EthAddress, Number) {
        let decodedInput = try unwrapLidoWstETHFn.decodeInput(input: input)
        switch decodedInput {
        case let .tuple2(.address(wstETH), .uint256(amount)):
            return  (wstETH, amount)
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, unwrapLidoWstETHFn.inputTuple)
        }
    }

    public static let unwrapWETHFn = ABI.Function(
            name: "unwrapWETH",
            inputs: [.address, .uint256],
            outputs: []
    )

    public static func unwrapWETH(weth: EthAddress, amount: Number, withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<(), RevertReason> {
            do {
                let query = try unwrapWETHFn.encoded(with: [.address(weth), .uint256(amount)])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try unwrapWETHFn.decode(output: result)

                switch decoded {
                case  .tuple0:
                    return .success(())
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, unwrapWETHFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func unwrapWETHDecode(input: Hex) throws -> (EthAddress, Number) {
        let decodedInput = try unwrapWETHFn.decodeInput(input: input)
        switch decodedInput {
        case let .tuple2(.address(weth), .uint256(amount)):
            return  (weth, amount)
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, unwrapWETHFn.inputTuple)
        }
    }

    public static let unwrapWETHUpToFn = ABI.Function(
            name: "unwrapWETHUpTo",
            inputs: [.address, .uint256],
            outputs: []
    )

    public static func unwrapWETHUpTo(weth: EthAddress, targetAmount: Number, withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<(), RevertReason> {
            do {
                let query = try unwrapWETHUpToFn.encoded(with: [.address(weth), .uint256(targetAmount)])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try unwrapWETHUpToFn.decode(output: result)

                switch decoded {
                case  .tuple0:
                    return .success(())
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, unwrapWETHUpToFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func unwrapWETHUpToDecode(input: Hex) throws -> (EthAddress, Number) {
        let decodedInput = try unwrapWETHUpToFn.decodeInput(input: input)
        switch decodedInput {
        case let .tuple2(.address(weth), .uint256(targetAmount)):
            return  (weth, targetAmount)
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, unwrapWETHUpToFn.inputTuple)
        }
    }

    public static let wrapAllETHFn = ABI.Function(
            name: "wrapAllETH",
            inputs: [.address],
            outputs: []
    )

    public static func wrapAllETH(weth: EthAddress, withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<(), RevertReason> {
            do {
                let query = try wrapAllETHFn.encoded(with: [.address(weth)])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try wrapAllETHFn.decode(output: result)

                switch decoded {
                case  .tuple0:
                    return .success(())
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, wrapAllETHFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func wrapAllETHDecode(input: Hex) throws -> (EthAddress) {
        let decodedInput = try wrapAllETHFn.decodeInput(input: input)
        switch decodedInput {
        case let .tuple1(.address(weth)):
            return  (weth)
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, wrapAllETHFn.inputTuple)
        }
    }

    public static let wrapAllLidoStETHFn = ABI.Function(
            name: "wrapAllLidoStETH",
            inputs: [.address, .address],
            outputs: []
    )

    public static func wrapAllLidoStETH(wstETH: EthAddress, stETH: EthAddress, withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<(), RevertReason> {
            do {
                let query = try wrapAllLidoStETHFn.encoded(with: [.address(wstETH), .address(stETH)])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try wrapAllLidoStETHFn.decode(output: result)

                switch decoded {
                case  .tuple0:
                    return .success(())
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, wrapAllLidoStETHFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func wrapAllLidoStETHDecode(input: Hex) throws -> (EthAddress, EthAddress) {
        let decodedInput = try wrapAllLidoStETHFn.decodeInput(input: input)
        switch decodedInput {
        case let .tuple2(.address(wstETH), .address(stETH)):
            return  (wstETH, stETH)
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, wrapAllLidoStETHFn.inputTuple)
        }
    }

    public static let wrapETHFn = ABI.Function(
            name: "wrapETH",
            inputs: [.address, .uint256],
            outputs: []
    )

    public static func wrapETH(weth: EthAddress, amount: Number, withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<(), RevertReason> {
            do {
                let query = try wrapETHFn.encoded(with: [.address(weth), .uint256(amount)])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try wrapETHFn.decode(output: result)

                switch decoded {
                case  .tuple0:
                    return .success(())
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, wrapETHFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func wrapETHDecode(input: Hex) throws -> (EthAddress, Number) {
        let decodedInput = try wrapETHFn.decodeInput(input: input)
        switch decodedInput {
        case let .tuple2(.address(weth), .uint256(amount)):
            return  (weth, amount)
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, wrapETHFn.inputTuple)
        }
    }

    public static let wrapETHUpToFn = ABI.Function(
            name: "wrapETHUpTo",
            inputs: [.address, .uint256],
            outputs: []
    )

    public static func wrapETHUpTo(weth: EthAddress, targetAmount: Number, withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<(), RevertReason> {
            do {
                let query = try wrapETHUpToFn.encoded(with: [.address(weth), .uint256(targetAmount)])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try wrapETHUpToFn.decode(output: result)

                switch decoded {
                case  .tuple0:
                    return .success(())
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, wrapETHUpToFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func wrapETHUpToDecode(input: Hex) throws -> (EthAddress, Number) {
        let decodedInput = try wrapETHUpToFn.decodeInput(input: input)
        switch decodedInput {
        case let .tuple2(.address(weth), .uint256(targetAmount)):
            return  (weth, targetAmount)
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, wrapETHUpToFn.inputTuple)
        }
    }

    public static let wrapLidoStETHFn = ABI.Function(
            name: "wrapLidoStETH",
            inputs: [.address, .address, .uint256],
            outputs: []
    )

    public static func wrapLidoStETH(wstETH: EthAddress, stETH: EthAddress, amount: Number, withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<(), RevertReason> {
            do {
                let query = try wrapLidoStETHFn.encoded(with: [.address(wstETH), .address(stETH), .uint256(amount)])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try wrapLidoStETHFn.decode(output: result)

                switch decoded {
                case  .tuple0:
                    return .success(())
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, wrapLidoStETHFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func wrapLidoStETHDecode(input: Hex) throws -> (EthAddress, EthAddress, Number) {
        let decodedInput = try wrapLidoStETHFn.decodeInput(input: input)
        switch decodedInput {
        case let .tuple3(.address(wstETH), .address(stETH), .uint256(amount)):
            return  (wstETH, stETH, amount)
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, wrapLidoStETHFn.inputTuple)
        }
    }

}