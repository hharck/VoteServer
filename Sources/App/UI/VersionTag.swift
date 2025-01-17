import Leaf
struct VersionTag: LeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        .string(App.version)
    }
}
