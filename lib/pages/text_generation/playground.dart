
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:inference/pages/models/widgets/grid_container.dart';
import 'package:inference/pages/text_generation/widgets/assistant_message.dart';
import 'package:inference/pages/text_generation/widgets/model_properties.dart';
import 'package:inference/pages/text_generation/widgets/user_message.dart';
import 'package:inference/project.dart';
import 'package:inference/providers/text_inference_provider.dart';
import 'package:inference/theme_fluent.dart';
import 'package:inference/widgets/device_selector.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class Playground extends StatefulWidget {
  final Project project;

  const Playground({required this.project, super.key});


  @override
  _PlaygroundState createState() => _PlaygroundState();
}

class SubmitMessageIntent extends Intent {}

class _PlaygroundState extends State<Playground> {
  final textController = TextEditingController();
  final scrollController = ScrollController();
  bool attachedToBottom = true;

  void jumpToBottom({ offset = 0 }) {
    if (scrollController.hasClients) {
      scrollController.jumpTo(scrollController.position.maxScrollExtent + offset);
    }
  }

  void message(String message) {
    if (message.isEmpty) return;
    final provider = Provider.of<TextInferenceProvider>(context, listen: false);
    if (!provider.initialized || provider.response != null) return;
    textController.text = '';
    jumpToBottom(offset: 110); //move to bottom including both
    // TODO: add error handling
    provider.message(message).catchError((e) { print(e); });
  }

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      setState(() {
        attachedToBottom = scrollController.position.pixels + 0.001 >= scrollController.position.maxScrollExtent;
      });
    });
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (attachedToBottom) {
      jumpToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    final nf = NumberFormat.decimalPatternDigits(
      locale: locale.languageCode, decimalDigits: 2);
    final theme = FluentTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer<TextInferenceProvider>(builder: (context, provider, child) =>
          Expanded(child: Column(
            children: [
              SizedBox(
                height: 64,
                child: GridContainer(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                          children: [
                            const DeviceSelector(),
                            const Divider(size: 24,direction: Axis.vertical,),
                            const SizedBox(width: 24,),
                            const Text('Temperature: '),
                            Slider(
                              value: provider.temperature,
                              onChanged: (value) { provider.temperature = value; },
                              label: nf.format(provider.temperature),
                              min: 0.1,
                              max: 2.0,
                            ),
                            const SizedBox(width: 24,),
                            const Text('Top P: '),
                            Slider(
                              value: provider.topP,
                              onChanged: (value) { provider.topP = value; },
                              label: nf.format(provider.topP),
                              max: 1.0,
                              min: 0.1,
                            ),
                          ],
                  )
                    ),
                  ),
                ),
             Expanded(child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.brightness.isDark ? backgroundColor.dark : theme.scaffoldBackgroundColor
                ),
               child: GridContainer(child: SizedBox(
                width: double.infinity,
                child: Builder(builder: (context) {
                  if (!provider.initialized) {
                    return const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 64,height: 64, child: ProgressRing()),
                        Padding(
                          padding: EdgeInsets.only(top: 18),
                          child: Text("Loading model..."),
                        )
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: Builder(builder: (context) {
                          if (provider.messages.isEmpty) {
                            return Center(
                              child: Text("Start chatting with ${provider.project?.name ?? "the model"}!"),
                            );
                          }
                          return Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              SingleChildScrollView(
                                controller: scrollController,
                                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 20), child: Column(
                                  children: provider.messages.map((message) { switch (message.speaker) {
                                    case Speaker.user: return UserMessage(message);
                                    case Speaker.system: return Text('System: ${message.message}');
                                    case Speaker.assistant: return AssistantMessage(message);
                                  }}).toList(),
                                ),),
                              ),
                              Positioned(
                                bottom: 10,
                                child: Builder(builder: (context) => attachedToBottom
                                  ? const SizedBox()
                                  : Padding(
                                    padding: const EdgeInsets.only(top:2),
                                    child: FilledButton(child: const Row(
                                      children: [
                                        Icon(FluentIcons.chevron_down, size: 12),
                                        SizedBox(width: 4),
                                        Text('Scroll to bottom'),
                                      ],
                                    ), onPressed: () {
                                      jumpToBottom();
                                      setState(() {
                                        attachedToBottom = true;
                                      });
                                    }),
                                  )
                                ),
                              )
                            ],
                          );
                        }),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Tooltip(
                              message: "Create new thread",
                              child: Button(child: const Icon(FluentIcons.rocket, size: 18,), onPressed: () {}),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Shortcuts(
                                    shortcuts: <LogicalKeySet, Intent>{
                                      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.enter): SubmitMessageIntent(),
                                      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.enter): SubmitMessageIntent(),
                                    },
                                    child: Actions(
                                      actions: <Type, Action<Intent>>{
                                        SubmitMessageIntent: CallbackAction<SubmitMessageIntent>(
                                          onInvoke: (SubmitMessageIntent intent) => message(textController.text),
                                        ),
                                      },
                                      child: TextBox(
                                        placeholder: "Type a message...",
                                        keyboardType: TextInputType.text,
                                        controller: textController,
                                        maxLines: null,
                                        expands: true,
                                        onSubmitted: message,
                                        autofocus: true,
                                      ),
                                    ),
                                  ),
                              ),
                            ),
                            Builder(builder: (context) => provider.interimResponse != null
                              ? Tooltip(
                                message: "Stop",
                                child: Button(child: const Icon(FluentIcons.stop, size: 18,), onPressed: () { provider.forceStop(); }),
                              )
                              : Tooltip(
                                message: "Send message",
                                child: Button(child: const Icon(FluentIcons.send, size: 18,), onPressed: () { message(textController.text); }),
                              )
                            )
                          ]
                        ),
                      )
                    ],
                  );
                }),
               )),
             )),
          ],
        ))),
        const ModelProperties(),
      ],
    );
  }
}