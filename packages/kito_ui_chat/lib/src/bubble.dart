// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'models.dart';
import 'rich_text.dart';
import 'strings.dart';
import 'style.dart';
import 'timeline.dart';
import 'voice.dart';

/// Called when a photo in a bubble is tapped, with where it sits on screen.
typedef KitoChatImageTap = void Function(
    KitoChatMessage message, KitoChatImage image, Rect? globalRect);

/// One message bubble — text, photo, voice note or system note — with its quoted reply and
/// reaction chips. `KitoChatView` lays these out for you; use it directly for custom layouts.
///
/// ```dart
/// KitoChatBubble(message, isOutgoing: true, position: KitoChatGroupPosition.last,
///     style: KitoChatBubbleStyle.imessage)
/// ```
class KitoChatBubble extends StatelessWidget {
  /// Creates a bubble for [message].
  const KitoChatBubble(
    this.message, {
    super.key,
    required this.isOutgoing,
    this.position = KitoChatGroupPosition.single,
    this.style = KitoChatBubbleStyle.modern,
    this.showsAuthorName = false,
    this.currentUserId,
    this.tint,
    this.onReactionTap,
    this.onQuoteTap,
    this.onImageTap,
    this.onLinkTap,
    this.audioPlayer,
    this.maxWidth = 300,
  });

  /// The message.
  final KitoChatMessage message;

  /// Whether it's yours (trailing side, tinted).
  final bool isOutgoing;

  /// Its place in a run from the same author.
  final KitoChatGroupPosition position;

  /// How it looks.
  final KitoChatBubbleStyle style;

  /// Write the author's name at the top — for the first message of a run in group chats.
  final bool showsAuthorName;

  /// Highlights your own reactions.
  final String? currentUserId;

  /// Overrides the primary colour.
  final Color? tint;

  /// Called with the emoji when a reaction chip is tapped.
  final ValueChanged<String>? onReactionTap;

  /// Called with the quoted message's id when the quote is tapped.
  final ValueChanged<String>? onQuoteTap;

  /// Called when the photo is tapped.
  final KitoChatImageTap? onImageTap;

  /// Called when a link in the text is tapped.
  final ValueChanged<Uri>? onLinkTap;

  /// Makes a real audio player for voice notes with a URL.
  final KitoChatAudioPlayer Function()? audioPlayer;

  /// The widest a text bubble grows.
  final double maxWidth;

  /// The width of a photo inside its bubble.
  static const imageWidth = 236.0;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final accent = KitoChatAccent.of(context, tint);
    final foreground = style.foreground(
        isOutgoing: isOutgoing, onTint: accent.onTint, theme: kito);
    final content = message.content;
    final Widget body = switch (content) {
      KitoChatSystemContent(:final text) => _SystemNote(text: text),
      KitoChatTextContent(:final text)
          when message.jumboEmojiCount != null && message.replyTo == null =>
        Padding(
          padding: EdgeInsets.symmetric(vertical: kito.spacing.xxs),
          child: Text(text,
              style: TextStyle(
                  fontSize: message.jumboEmojiCount == 1 ? 56 : 44,
                  height: 1.15)),
        ),
      KitoChatTextContent(:final text) => _chrome(
          context,
          accent,
          foreground,
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: kito.spacing.md + 2, vertical: kito.spacing.sm + 1),
            child: KitoChatText(
              text,
              style: kito.typography.body.copyWith(color: foreground),
              linkColor:
                  style.fillsOutgoing(isOutgoing) ? foreground : accent.tint,
              onLinkTap: onLinkTap,
            ),
          ),
        ),
      KitoChatImageContent(:final image) =>
        _imageBubble(context, image, accent, foreground),
      KitoChatVoiceContent() => _chrome(
          context,
          accent,
          foreground,
          Padding(
            padding: EdgeInsetsDirectional.only(
                start: kito.spacing.xs,
                end: kito.spacing.sm,
                top: kito.spacing.xxs,
                bottom: kito.spacing.xs),
            child: KitoChatVoiceNote(
              voice: content,
              seed: message.id,
              foreground: foreground,
              accent: accent.tint,
              onAccent: accent.onTint,
              onFill: style.fillsOutgoing(isOutgoing),
              audioPlayer: audioPlayer,
            ),
          ),
        ),
    };
    if (message.reactions.isEmpty || message.isSystem) return body;
    return Stack(clipBehavior: Clip.none, children: [
      Padding(padding: const EdgeInsets.only(bottom: 18), child: body),
      PositionedDirectional(
        bottom: 0,
        start: isOutgoing ? -6 : null,
        end: isOutgoing ? null : -6,
        child: KitoChatReactionChips(
          reactions: message.reactions,
          currentUserId: currentUserId,
          tint: accent.tint,
          onTap: onReactionTap,
        ),
      ),
    ]);
  }

  bool get _showsHeader => showsAuthorName || message.replyTo != null;

  Widget _header(
      BuildContext context, KitoChatAccent accent, Color foreground) {
    final kito = context.kito;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showsAuthorName)
          Padding(
            padding: EdgeInsetsDirectional.only(
                start: kito.spacing.xs, end: kito.spacing.xs, bottom: 2),
            child: Text(
              message.author.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: kito.typography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: KitoChatPalette.nameColorFor(message.author),
              ),
            ),
          ),
        if (message.replyTo case final reply?)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap:
                onQuoteTap == null ? null : () => onQuoteTap!(reply.messageId),
            child: KitoChatQuotedReply(
              reply: reply,
              onFill: style.fillsOutgoing(isOutgoing),
              foreground: foreground,
              tint: accent.tint,
            ),
          ),
      ],
    );
  }

  Widget _chrome(BuildContext context, KitoChatAccent accent, Color foreground,
      Widget content) {
    final kito = context.kito;
    final hasTail =
        style.tail != KitoChatBubbleTail.none && position.isGroupEnd;
    Widget inner = content;
    if (_showsHeader) {
      inner = IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(
                  start: kito.spacing.sm,
                  end: kito.spacing.sm,
                  top: kito.spacing.sm),
              child: _header(context, accent, foreground),
            ),
            content,
          ],
        ),
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: KitoChatBubbleBackground(
        style: style,
        isOutgoing: isOutgoing,
        position: position,
        tint: tint,
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: hasTail && !isOutgoing ? 3 : 0,
            end: hasTail && isOutgoing ? 3 : 0,
          ),
          child: inner,
        ),
      ),
    );
  }

  Widget _imageBubble(BuildContext context, KitoChatImage image,
      KitoChatAccent accent, Color foreground) {
    final kito = context.kito;
    final caption = image.caption;
    return SizedBox(
      width: imageWidth + 6,
      child: KitoChatBubbleBackground(
        style: style,
        isOutgoing: isOutgoing,
        position: position,
        tint: tint,
        showsTail: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_showsHeader)
              Padding(
                padding: EdgeInsetsDirectional.only(
                    start: kito.spacing.sm,
                    end: kito.spacing.sm,
                    top: kito.spacing.sm,
                    bottom: kito.spacing.xs),
                child: _header(context, accent, foreground),
              ),
            Padding(
              padding: const EdgeInsets.all(3),
              child: KitoChatPhoto(
                image: image,
                radius: math.max(4, style.cornerRadius - 4),
                onTap: onImageTap == null
                    ? null
                    : (rect) => onImageTap!(message, image, rect),
              ),
            ),
            if (caption != null && caption.trim().isNotEmpty)
              Padding(
                padding: EdgeInsetsDirectional.only(
                    start: kito.spacing.md,
                    end: kito.spacing.md,
                    top: kito.spacing.xs,
                    bottom: kito.spacing.sm),
                child: KitoChatText(
                  caption,
                  style: kito.typography.body.copyWith(color: foreground),
                  linkColor: style.fillsOutgoing(isOutgoing)
                      ? foreground
                      : accent.tint,
                  onLinkTap: onLinkTap,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SystemNote extends StatelessWidget {
  const _SystemNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: kito.spacing.md, vertical: kito.spacing.xs + 2),
        decoration: BoxDecoration(
          color: kito.colors.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(kito.radii.pill),
          border: Border.all(color: kito.colors.border.withValues(alpha: 0.5)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: kito.typography.caption
              .copyWith(color: kito.colors.onSurface.withValues(alpha: 0.7)),
        ),
      ),
    );
  }
}

// MARK: - Photo

/// A photo sized to its aspect ratio with a soft placeholder while it loads. Tap to open it.
class KitoChatPhoto extends StatelessWidget {
  /// Creates a photo.
  const KitoChatPhoto({
    super.key,
    required this.image,
    this.width = KitoChatBubble.imageWidth,
    this.radius = 16,
    this.onTap,
    this.fit = BoxFit.cover,
    this.fixedHeight = true,
  });

  /// The photo.
  final KitoChatImage image;

  /// Its width.
  final double width;

  /// Corner radius.
  final double radius;

  /// Called with the photo's rect on screen.
  final ValueChanged<Rect?>? onTap;

  /// How it fills its box.
  final BoxFit fit;

  /// Clamp the height between 140 and 320 (bubble) rather than using the true ratio.
  final bool fixedHeight;

  /// The height of a bubble photo for [aspectRatio].
  static double heightFor(double aspectRatio,
          {double width = KitoChatBubble.imageWidth}) =>
      (width / math.max(0.2, aspectRatio)).clamp(140.0, 320.0);

  @override
  Widget build(BuildContext context) {
    final height = fixedHeight
        ? heightFor(image.aspectRatio, width: width)
        : width / image.aspectRatio;
    final caption = image.caption;
    final Widget picture = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: KitoChatImageView(image: image, fit: fit),
      ),
    );
    return Semantics(
      image: true,
      button: onTap != null,
      label: caption == null || caption.trim().isEmpty
          ? KitoChatStrings.of(context, 'photo')
          : KitoChatStrings.of(context, 'photoCaption', {'caption': caption}),
      hint: onTap != null ? KitoChatStrings.of(context, 'openPhoto') : null,
      onTap: onTap == null ? null : () => onTap!(_rectOf(context)),
      child: ExcludeSemantics(
        child: Builder(
          builder: (inner) => GestureDetector(
            onTap: onTap == null ? null : () => onTap!(_rectOf(inner)),
            child: ColoredBox(color: Colors.transparent, child: picture),
          ),
        ),
      ),
    );
  }

  static Rect? _rectOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

/// Draws a [KitoChatImage] with a fade-in, a muted placeholder while loading and a broken-photo
/// glyph on failure.
class KitoChatImageView extends StatelessWidget {
  /// Creates an image view.
  const KitoChatImageView(
      {super.key, required this.image, this.fit = BoxFit.cover});

  /// The photo.
  final KitoChatImage image;

  /// How it fills its box.
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return ColoredBox(
      color: kito.colors.surfaceMuted,
      child: Image(
        image: image.image,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        frameBuilder: (context, child, frame, sync) => AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration:
              sync ? Duration.zero : KitoMotion.of(context, kito.motion.medium),
          child: child,
        ),
        errorBuilder: (context, _, __) => Center(
          child: Icon(Icons.broken_image_outlined,
              size: 28, color: kito.colors.onSurface.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}

// MARK: - Quoted reply

/// The quote inside a bubble (and above the composer) that a reply points to.
class KitoChatQuotedReply extends StatelessWidget {
  /// Creates a quote.
  const KitoChatQuotedReply({
    super.key,
    required this.reply,
    this.onFill = false,
    this.foreground,
    this.tint,
    this.maxLines = 2,
  });

  /// What's quoted.
  final KitoChatReply reply;

  /// True inside a bubble filled with the accent.
  final bool onFill;

  /// The bubble's text colour.
  final Color? foreground;

  /// Overrides the primary colour.
  final Color? tint;

  /// Preview lines.
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final fg = foreground ?? kito.colors.onSurface;
    final accent = kito.accent(tint);
    return Semantics(
      container: true,
      label: KitoChatStrings.of(context, 'replyingToQuote',
          {'name': reply.authorName, 'text': reply.preview}),
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            color: onFill
                ? fg.withValues(alpha: 0.14)
                : accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(kito.radii.md),
          ),
          padding: EdgeInsetsDirectional.only(
              start: kito.spacing.xs + 2,
              end: kito.spacing.sm,
              top: kito.spacing.xs + 2,
              bottom: kito.spacing.xs + 2),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: onFill ? fg.withValues(alpha: 0.85) : accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: kito.spacing.sm),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reply.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: kito.typography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: onFill ? fg : accent),
                      ),
                      const SizedBox(height: 1),
                      Text.rich(
                        TextSpan(children: [
                          if (reply.icon != null)
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(end: 4),
                                child: Icon(reply.icon,
                                    size: 13,
                                    color: onFill
                                        ? fg.withValues(alpha: 0.8)
                                        : kito.colors.onSurface
                                            .withValues(alpha: 0.7)),
                              ),
                            ),
                          TextSpan(text: reply.preview),
                        ]),
                        maxLines: maxLines,
                        overflow: TextOverflow.ellipsis,
                        style: kito.typography.caption.copyWith(
                            color: onFill
                                ? fg.withValues(alpha: 0.8)
                                : kito.colors.onSurface.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// MARK: - Reaction chips

/// Emoji chips under a bubble with counts; your own reaction is tinted. Chips pop in and out.
class KitoChatReactionChips extends StatelessWidget {
  /// Creates reaction chips.
  const KitoChatReactionChips({
    super.key,
    required this.reactions,
    this.currentUserId,
    this.tint,
    this.onTap,
  });

  /// The reactions.
  final List<KitoChatReaction> reactions;

  /// Highlights this person's reaction.
  final String? currentUserId;

  /// Overrides the primary colour.
  final Color? tint;

  /// Called with the emoji when a chip is tapped.
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final accent = kito.accent(tint);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (final r in reactions)
        Padding(
          key: ValueKey(r.emoji),
          padding: const EdgeInsetsDirectional.only(end: 4),
          child: _PopIn(
            child: Semantics(
              button: onTap != null,
              selected: currentUserId != null && r.includes(currentUserId!),
              label: '${r.emoji} ${r.count}',
              onTap: onTap == null ? null : () => onTap!(r.emoji),
              child: ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap == null ? null : () => onTap!(r.emoji),
                  child: _chip(context, r, accent,
                      currentUserId != null && r.includes(currentUserId!)),
                ),
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _chip(
      BuildContext context, KitoChatReaction r, Color accent, bool mine) {
    final kito = context.kito;
    return AnimatedContainer(
      duration: KitoMotion.of(context, kito.motion.fast),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: mine
            ? Color.alphaBlend(
                accent.withValues(alpha: 0.16), kito.colors.surface)
            : kito.colors.surface,
        borderRadius: BorderRadius.circular(kito.radii.pill),
        border: Border.all(
            color: mine ? accent.withValues(alpha: 0.6) : kito.colors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 3,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(r.emoji, style: const TextStyle(fontSize: 14, height: 1.2)),
        if (r.count > 1) ...[
          const SizedBox(width: 3),
          AnimatedSwitcher(
            duration: KitoMotion.of(context, kito.motion.fast),
            transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.5), end: Offset.zero)
                      .animate(a),
                  child: c),
            ),
            child: Text(
              '${r.count}',
              key: ValueKey(r.count),
              style: kito.typography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: mine
                    ? accent
                    : kito.colors.onSurface.withValues(alpha: 0.75),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

/// Springs its child in from small the first time it's built.
class _PopIn extends StatefulWidget {
  const _PopIn({required this.child});
  final Widget child;

  @override
  State<_PopIn> createState() => _PopInState();
}

class _PopInState extends State<_PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.status == AnimationStatus.dismissed) {
      if (context.reduceMotion) {
        _c.value = 1;
      } else {
        _c.forward();
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = context.kito.motion.spring.transform(_c.value);
        return Opacity(
          opacity: _c.value.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.3 + 0.7 * t, child: child),
        );
      },
      child: widget.child,
    );
  }
}
