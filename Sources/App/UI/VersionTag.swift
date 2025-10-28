import Leaf
struct VersionTag: LeafTag {
    func render(_ ctx: LeafContext) -> LeafData {
        .string(App.version)
    }
}
