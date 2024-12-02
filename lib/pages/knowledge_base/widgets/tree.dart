import 'package:fluent_ui/fluent_ui.dart';
import 'package:inference/pages/knowledge_base/providers/knowledge_base_provider.dart';
import 'package:inference/pages/knowledge_base/widgets/group_item.dart';
import 'package:inference/pages/models/widgets/grid_container.dart';
import 'package:inference/theme_fluent.dart';
import 'package:provider/provider.dart';

class Tree extends StatefulWidget {
  const Tree({
      super.key
  });

  @override
  State<Tree> createState() => _TreeState();
}

class _TreeState extends State<Tree> {
  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Consumer<KnowledgeBaseProvider>(
      builder: (context, data, child) {
        return GridContainer(
          color: backgroundColor.of(theme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  for (final group in data.groups)
                    GroupItem(
                      isActive: data.activeGroup == group.internalId,
                      editable: data.isEditingId == group.internalId,
                      group: group,
                      onActivate: () {
                        data.activeGroup = group.internalId;
                      },
                      onRename: (value) => data.renameGroup(group, value),
                      onMakeEditable: () {
                        setState(() {
                            data.isEditingId = group.internalId;
                        });
                      },
                      onDelete: () => data.deleteGroup(group),
                    ),
                ]
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Button(
                  onPressed: data.addGroup,
                  child: const Text("Add group"),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}
