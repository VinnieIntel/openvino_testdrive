import 'package:fluent_ui/fluent_ui.dart';
import 'package:inference/langchain/object_box/embedding_entity.dart';
import 'package:inference/langchain/object_box/object_box.dart';
import 'package:inference/langchain/openvino_embeddings.dart';
import 'package:inference/objectbox.g.dart';
import 'package:inference/pages/models/widgets/grid_container.dart';
import 'package:inference/theme_fluent.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class KnowledgeBase extends StatefulWidget {
  const KnowledgeBase({super.key});

  @override
  State<KnowledgeBase> createState() => _KnowledgeBaseState();
}

class _KnowledgeBaseState extends State<KnowledgeBase> {
  final controller = TextEditingController();
  late Box<EmbeddingEntity> embeddingsBox;
  late Box<KnowledgeGroup> groupBox;
  OpenVINOEmbeddings? embeddingsModel;

  List<KnowledgeGroup> groups = [];
  int? editId;

  void initEmbeddings() async {
    final platformContext = Context(style: Style.platform);
    final directory = await getApplicationSupportDirectory();
    final device = "CPU";
    final embeddingsModelPath = platformContext.join(directory.path, "test", "all-MiniLM-L6-v2", "fp16");
    embeddingsModel = await OpenVINOEmbeddings.init(embeddingsModelPath, device);

  }
  @override
  void initState() {
    super.initState();

    embeddingsBox = ObjectBox.instance.store.box<EmbeddingEntity>();
    groupBox = ObjectBox.instance.store.box<KnowledgeGroup>();
    groupBox.getAllAsync().then((b) {
        setState(() {
            groups = b;
        });
    });
  }

  void test() async {
    print("all embeddings: ");
    for (final embedding in embeddingsBox.getAll()) {
      print(embedding.content);
    }
    final promptEmbeddings = await embeddingsModel!.embedQuery(controller.text);
    final query = embeddingsBox
      .query(EmbeddingEntity_.embeddings.nearestNeighborsF32(promptEmbeddings, 2))
      .build();

    final results = query.findWithScores();
    for (final result in results) {
      print("Embedding ID: ${result.object.id}, distance: ${result.score}, text: ${result.object.document.target!.source}");
    }

    //final output = chain!.invoke(controller.text);
    //setState(() {
    //  response = output.then((p) => p.toString());
    //});
  }

  void renameGroup(KnowledgeGroup group, String value) {
    setState(() {
      editId = null;
      groupBox.put(group..name = value);
    });
  }

  void deleteGroup(KnowledgeGroup group) {
    groupBox.remove(group.internalId);
    setState(() {
        groups.remove(group);
    });
  }

  void addGroup() {
    setState(() {
      editId = groupBox.put(KnowledgeGroup("New group"));
      groups = groupBox.getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: () {
        if (editId != null) {
          setState(() {
              editId = null;
          });
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GridContainer(
                  color: backgroundColor.of(theme),
                  padding: const EdgeInsets.all(16),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                  ),
                  child: const Text("Knowledge Base",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: GridContainer(
                    color: backgroundColor.of(theme),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TreeView(
                          items: [
                            for (final group in groups)
                              TreeViewItem(
                                content: GroupItem(
                                  editable: group.internalId == editId,
                                  group: group,
                                  onRename: (value) => renameGroup(group, value),
                                  onMakeEditable: () {
                                    setState(() {
                                        editId = group.internalId;
                                    });
                                  },
                                  onDelete: () => deleteGroup(group),
                                )
                              ),
                          ]
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Button(
                            onPressed: addGroup,
                            child: const Text("Add group"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GroupItem extends StatefulWidget {
  final KnowledgeGroup group;
  final bool editable;
  final Function(String)? onRename;
  final Function()? onDelete;
  final Function()? onMakeEditable;
  const GroupItem({super.key, required this.group, required this.editable, this.onRename, this.onDelete, this.onMakeEditable});

  @override
  State<GroupItem> createState() => _GroupItemState();
}

class _GroupItemState extends State<GroupItem> {
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.text = widget.group.name;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.editable) {
      return TextBox(
        controller: controller,
        onSubmitted: (value) {
          widget.onRename?.call(value);
        },
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: () {
        widget.onMakeEditable?.call();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.group.name),
          IconButton(icon: const Icon(FluentIcons.delete_rows), onPressed: () {
              widget.onDelete?.call();
          }),
        ],
      ),
    );
  }
}
