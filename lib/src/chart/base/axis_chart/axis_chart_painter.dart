import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/bar_chart/bar_chart_painter.dart';
import 'package:fl_chart/src/chart/base/axis_chart/axis_chart_helper.dart';
import 'package:fl_chart/src/chart/base/base_chart/base_chart_painter.dart';
import 'package:fl_chart/src/chart/line_chart/line_chart_painter.dart';
import 'package:fl_chart/src/extensions/paint_extension.dart';
import 'package:fl_chart/src/utils/canvas_wrapper.dart';
import 'package:fl_chart/src/utils/utils.dart';
import 'package:flutter/material.dart';

/// This class is responsible to draw the grid behind all axis base charts.
/// also we have two useful function [getPixelX] and [getPixelY] that used
/// in child classes -> [BarChartPainter], [LineChartPainter]
/// [dataList] is the currently showing data (it may produced by an animation using lerp function),
/// [targetData] is the target data, that animation is going to show (if animating)
abstract class AxisChartPainter<D extends AxisChartData>
    extends BaseChartPainter<D> {
  AxisChartPainter() {
    _gridPaint = Paint()..style = PaintingStyle.stroke;

    _backgroundPaint = Paint()..style = PaintingStyle.fill;

    _rangeAnnotationPaint = Paint()..style = PaintingStyle.fill;

    _extraLinesPaint = Paint()..style = PaintingStyle.stroke;

    _imagePaint = Paint();

    _clipPaint = Paint();
  }

  late Paint _gridPaint;
  late Paint _backgroundPaint;
  late Paint _extraLinesPaint;
  late Paint _imagePaint;
  late Paint _clipPaint;

  /// [_rangeAnnotationPaint] draws range annotations;
  late Paint _rangeAnnotationPaint;

  /// Paints [AxisChartData] into the provided canvas.
  @override
  void paint(
    BuildContext context,
    CanvasWrapper canvasWrapper,
    PaintHolder<D> holder,
  ) {
    super.paint(context, canvasWrapper, holder);
    drawBackground(canvasWrapper, holder);
    drawRangeAnnotation(canvasWrapper, holder);
    drawGrid(canvasWrapper, holder);
  }

  @visibleForTesting
  void drawGrid(CanvasWrapper canvasWrapper, PaintHolder<D> holder) {
    final data = holder.data;
    if (!data.gridData.show) {
      return;
    }
    final viewSize = canvasWrapper.size;
    // Show Vertical Grid
    if (data.gridData.drawVerticalLine) {
      final verticalInterval = data.gridData.verticalInterval ??
          Utils().getEfficientInterval(
            viewSize.width,
            data.horizontalDiff,
          );
      final axisValues = AxisChartHelper().iterateThroughAxis(
        min: data.minX,
        max: data.maxX,
        baseLine: data.baselineX,
        interval: verticalInterval,
      );
      for (final axisValue in axisValues) {
        if (!data.gridData.checkToShowVerticalLine(axisValue)) {
          continue;
        }
        final bothX = getPixelX(axisValue, viewSize, holder);
        final x1 = bothX;
        const y1 = 0.0;
        final x2 = bothX;
        final y2 = viewSize.height;
        final from = Offset(x1, y1);
        final to = Offset(x2, y2);

        final flLineStyle = data.gridData.getDrawingVerticalLine(axisValue);
        _gridPaint
          ..setColorOrGradientForLine(
            flLineStyle.color,
            flLineStyle.gradient,
            from: from,
            to: to,
          )
          ..strokeWidth = flLineStyle.strokeWidth
          ..transparentIfWidthIsZero();

        canvasWrapper.drawDashedLine(
          from,
          to,
          _gridPaint,
          flLineStyle.dashArray,
        );
      }
    }

    // Show Horizontal Grid
    if (data.gridData.drawHorizontalLine) {
      final horizontalInterval = data.gridData.horizontalInterval ??
          Utils().getEfficientInterval(viewSize.height, data.verticalDiff);

      final axisValues = AxisChartHelper().iterateThroughAxis(
        min: data.minY,
        minIncluded: false,
        max: data.maxY,
        maxIncluded: false,
        baseLine: data.baselineY,
        interval: horizontalInterval,
      );
      for (final axisValue in axisValues) {
        if (!data.gridData.checkToShowHorizontalLine(axisValue)) {
          continue;
        }
        final flLine = data.gridData.getDrawingHorizontalLine(axisValue);

        final bothY = getPixelY(axisValue, viewSize, holder);
        const x1 = 0.0;
        final y1 = bothY;
        final x2 = viewSize.width;
        final y2 = bothY;
        final from = Offset(x1, y1);
        final to = Offset(x2, y2);

        _gridPaint
          ..setColorOrGradientForLine(
            flLine.color,
            flLine.gradient,
            from: from,
            to: to,
          )
          ..strokeWidth = flLine.strokeWidth
          ..transparentIfWidthIsZero();

        canvasWrapper.drawDashedLine(
          from,
          to,
          _gridPaint,
          flLine.dashArray,
        );
      }
    }
  }

  /// This function draws a colored background behind the chart.
  @visibleForTesting
  void drawBackground(CanvasWrapper canvasWrapper, PaintHolder<D> holder) {
    final data = holder.data;
    if (data.backgroundColor.a == 0.0) {
      return;
    }

    final viewSize = canvasWrapper.size;
    _backgroundPaint.color = data.backgroundColor;
    canvasWrapper.drawRect(
      Rect.fromLTWH(0, 0, viewSize.width, viewSize.height),
      _backgroundPaint,
    );
  }

  @visibleForTesting
  void drawRangeAnnotation(CanvasWrapper canvasWrapper, PaintHolder<D> holder) {
    final data = holder.data;
    final viewSize = canvasWrapper.size;

    if (data.rangeAnnotations.verticalRangeAnnotations.isNotEmpty) {
      for (final annotation in data.rangeAnnotations.verticalRangeAnnotations) {
        final from = Offset(getPixelX(annotation.x1, viewSize, holder), 0);
        final to = Offset(
          getPixelX(annotation.x2, viewSize, holder),
          viewSize.height,
        );

        final rect = Rect.fromPoints(from, to);

        _rangeAnnotationPaint.setColorOrGradient(
          annotation.color,
          annotation.gradient,
          rect,
        );

        canvasWrapper.drawRect(rect, _rangeAnnotationPaint);
      }
    }

    if (data.rangeAnnotations.horizontalRangeAnnotations.isNotEmpty) {
      for (final annotation
          in data.rangeAnnotations.horizontalRangeAnnotations) {
        final from = Offset(0, getPixelY(annotation.y1, viewSize, holder));
        final to = Offset(
          viewSize.width,
          getPixelY(annotation.y2, viewSize, holder),
        );

        final rect = Rect.fromPoints(from, to);

        _rangeAnnotationPaint.setColorOrGradient(
          annotation.color,
          annotation.gradient,
          rect,
        );

        canvasWrapper.drawRect(rect, _rangeAnnotationPaint);
      }
    }
  }

  void drawExtraLines(
    BuildContext context,
    CanvasWrapper canvasWrapper,
    PaintHolder<D> holder,
  ) {
    if (holder.chartVirtualRect != null) {
      canvasWrapper.restore();
    }

    super.paint(context, canvasWrapper, holder);
    final data = holder.data;
    final viewSize = canvasWrapper.size;

    if (data.extraLinesData.horizontalLines.isNotEmpty) {
      drawHorizontalLines(context, canvasWrapper, holder, viewSize);
    }

    if (data.extraLinesData.verticalLines.isNotEmpty) {
      drawVerticalLines(context, canvasWrapper, holder, viewSize);
    }

    if (holder.chartVirtualRect != null) {
      canvasWrapper
        ..saveLayer(
          Offset.zero & canvasWrapper.size,
          _clipPaint,
        )
        ..clipRect(Offset.zero & canvasWrapper.size);
    }
  }

  void drawHorizontalLines(
    BuildContext context,
    CanvasWrapper canvasWrapper,
    PaintHolder<D> holder,
    Size viewSize,
  ) {
    for (final line in holder.data.extraLinesData.horizontalLines) {
      final from = Offset(0, getPixelY(line.y, viewSize, holder));
      final to = Offset(viewSize.width, getPixelY(line.y, viewSize, holder));

      final isLineOutsideOfChart = from.dy < 0 ||
          to.dy < 0 ||
          from.dy > viewSize.height ||
          to.dy > viewSize.height;

      if (!isLineOutsideOfChart) {
        _extraLinesPaint
          ..setColorOrGradientForLine(
            line.color,
            line.gradient,
            from: from,
            to: to,
          )
          ..strokeWidth = line.strokeWidth
          ..transparentIfWidthIsZero()
          ..strokeCap = line.strokeCap;

        canvasWrapper.drawDashedLine(
          from,
          to,
          _extraLinesPaint,
          line.dashArray,
        );

        if (line.sizedPicture != null) {
          final centerX = line.sizedPicture!.width / 2;
          final centerY = line.sizedPicture!.height / 2;
          final xPosition = centerX;
          final yPosition = to.dy - centerY;

          canvasWrapper
            ..save()
            ..translate(xPosition, yPosition)
            ..drawPicture(line.sizedPicture!.picture)
            ..restore();
        }

        if (line.image != null) {
          final centerX = line.image!.width / 2;
          final centerY = line.image!.height / 2;
          final centeredImageOffset = Offset(centerX, to.dy - centerY);
          canvasWrapper.drawImage(
            line.image!,
            centeredImageOffset,
            _imagePaint,
          );
        }

        if (line.label.show) {
          final label = line.label;
          final style = TextStyle(fontSize: 13, color: line.color, overflow: TextOverflow.fade, fontWeight: FontWeight.w600).merge(label.style);
          final padding = (label.padding as EdgeInsets).copyWith(
            left: (label.padding as EdgeInsets).left + 4,
            right: (label.padding as EdgeInsets).right + 4,
            top: (label.padding as EdgeInsets).top + 2,
            bottom: (label.padding as EdgeInsets).bottom + 2,
          );

          final labelText = label.labelResolver(line);
          final firstValue = labelText.split(' ').first;
          final span = TextSpan(
            text: firstValue,
            style: Utils().getThemeAwareTextStyle(context, style.copyWith(fontSize: (style.fontSize ?? 13) + 1, letterSpacing: .4)),
          );

          final tp = TextPainter(
            text: span,
            textDirection: TextDirection.ltr,
            maxLines: 1,
            textAlign: TextAlign.center,
          )..layout();

          switch (label.direction) {
            case LabelDirection.horizontal:
              canvasWrapper.drawText(
                tp,
                label.alignment.withinRect(
                  Rect.fromLTRB(
                    from.dx + padding.left,
                    from.dy - padding.bottom - tp.height,
                    viewSize.width,
                    to.dy + padding.top,
                  ),
                ),
              );
            case LabelDirection.vertical:
              canvasWrapper.drawVerticalText(
                tp,
                label.alignment.withinRect(
                  Rect.fromLTRB(
                    from.dx + padding.left + tp.height,
                    from.dy - padding.bottom - tp.width,
                    to.dx - padding.right,
                    to.dy + padding.top,
                  ),
                ),
              );
          }
        }
      }
    }
  }

  void drawVerticalLines(
    BuildContext context,
    CanvasWrapper canvasWrapper,
    PaintHolder<D> holder,
    Size viewSize,
  ) {
    for (final line in holder.data.extraLinesData.verticalLines) {
      final from = Offset(getPixelX(line.x, viewSize, holder), 0);
      final to = Offset(getPixelX(line.x, viewSize, holder), viewSize.height);

      final isLineOutsideOfChart = from.dx < 0 ||
          to.dx < 0 ||
          from.dx > viewSize.width ||
          to.dx > viewSize.width;

      if (!isLineOutsideOfChart) {
        _extraLinesPaint
          ..setColorOrGradientForLine(
            line.color,
            line.gradient,
            from: from,
            to: to,
          )
          ..strokeWidth = line.strokeWidth
          ..transparentIfWidthIsZero()
          ..strokeCap = line.strokeCap;

        canvasWrapper.drawDashedLine(
          from,
          to,
          _extraLinesPaint,
          line.dashArray,
        );

        if (line.sizedPicture != null) {
          final centerX = line.sizedPicture!.width / 2;
          final centerY = line.sizedPicture!.height / 2;
          final xPosition = to.dx - centerX;
          final yPosition = viewSize.height - centerY;

          canvasWrapper
            ..save()
            ..translate(xPosition, yPosition)
            ..drawPicture(line.sizedPicture!.picture)
            ..restore();
        }

        if (line.image != null) {
          final centerX = line.image!.width / 2;
          final centerY = line.image!.height + 2;
          final centeredImageOffset =
              Offset(to.dx - centerX, viewSize.height - centerY);
          canvasWrapper.drawImage(
            line.image!,
            centeredImageOffset,
            _imagePaint,
          );
        }

        if (line.label.show) {
          final label = line.label;
          final style =
              TextStyle(fontSize: 11, color: line.color).merge(label.style);
          final padding = label.padding as EdgeInsets;

          final span = TextSpan(
            text: label.labelResolver(line),
            style: Utils().getThemeAwareTextStyle(context, style),
          );

          final tp = TextPainter(
            text: span,
            textDirection: TextDirection.ltr,
          )..layout();

          switch (label.direction) {
            case LabelDirection.horizontal:
              canvasWrapper.drawText(
                tp,
                label.alignment.withinRect(
                  Rect.fromLTRB(
                    from.dx - padding.right - tp.width,
                    from.dy + padding.top,
                    to.dx + padding.left,
                    to.dy - padding.bottom - tp.height,
                  ),
                ),
              );
            case LabelDirection.vertical:
              canvasWrapper.drawVerticalText(
                tp,
                label.alignment.withinRect(
                  Rect.fromLTRB(
                    from.dx - padding.right,
                    from.dy + padding.top,
                    to.dx + padding.left + tp.height,
                    to.dy - padding.bottom - tp.width,
                  ),
                ),
              );
          }
        }
      }
    }
  }

  /// With this function we can convert our [FlSpot] x
  /// to the view base axis x .
  /// the view 0, 0 is on the top/left, but the spots is bottom/left
  double getPixelX(
    double spotX,
    Size viewSize,
    PaintHolder<D> holder,
  ) {
    final usableSize = holder.getChartUsableSize(viewSize);

    final pixelXUnadjusted = _getPixelX(spotX, holder.data, usableSize);

    // Adjust the position relative to the canvas if chartVirtualRect
    // is provided
    final adjustment = holder.chartVirtualRect?.left ?? 0;
    return pixelXUnadjusted + adjustment;
  }

  double _getPixelX(double spotX, D data, Size usableSize) {
    final deltaX = data.maxX - data.minX;
    if (deltaX == 0.0) {
      return 0;
    }
    return ((spotX - data.minX) / deltaX) * usableSize.width;
  }

  /// With this function we can convert our [FlSpot] y
  /// to the view base axis y.
  double getPixelY(
    double spotY,
    Size viewSize,
    PaintHolder<D> holder,
  ) {
    final usableSize = holder.getChartUsableSize(viewSize);

    final pixelYUnadjusted = _getPixelY(spotY, holder.data, usableSize);

    // Adjust the position relative to the canvas if chartVirtualRect
    // is provided
    final adjustment = holder.chartVirtualRect?.top ?? 0;
    return pixelYUnadjusted + adjustment;
  }

  double _getPixelY(double spotY, D data, Size usableSize) {
    final deltaY = data.maxY - data.minY;
    if (deltaY == 0.0) {
      return usableSize.height;
    }
    return usableSize.height -
        (((spotY - data.minY) / deltaY) * usableSize.height);
  }

  /// Converts pixel X position to axis X coordinates
  double getXForPixel(
    double pixelX,
    Size viewSize,
    PaintHolder<D> holder,
  ) {
    final usableSize = holder.getChartUsableSize(viewSize);
    final adjustment = holder.chartVirtualRect?.left ?? 0;
    final unadjustedPixelX = pixelX - adjustment;

    final deltaX = holder.data.maxX - holder.data.minX;
    if (deltaX == 0.0) return holder.data.minX;

    return (unadjustedPixelX / usableSize.width) * deltaX + holder.data.minX;
  }

  /// Converts pixel Y position to axis Y coordinates
  double getYForPixel(
    double pixelY,
    Size viewSize,
    PaintHolder<D> holder,
  ) {
    final usableSize = holder.getChartUsableSize(viewSize);
    final adjustment = holder.chartVirtualRect?.top ?? 0;
    final unadjustedPixelY = pixelY - adjustment;

    final deltaY = holder.data.maxY - holder.data.minY;
    if (deltaY == 0.0) return holder.data.minY;

    return holder.data.maxY - (unadjustedPixelY / usableSize.height) * deltaY;
  }

  /// Converts pixel coordinates to chart coordinates
  Offset getChartCoordinateFromPixel(
    Offset pixelOffset,
    Size viewSize,
    PaintHolder<D> holder,
  ) =>
      Offset(
        getXForPixel(pixelOffset.dx, viewSize, holder),
        getYForPixel(pixelOffset.dy, viewSize, holder),
      );

  /// With this function we can get horizontal
  /// position for the tooltip.
  double getTooltipLeft(
    double dx,
    double tooltipWidth,
    FLHorizontalAlignment tooltipHorizontalAlignment,
    double tooltipHorizontalOffset,
  ) =>
      switch (tooltipHorizontalAlignment) {
        FLHorizontalAlignment.center =>
          dx - (tooltipWidth / 2) + tooltipHorizontalOffset,
        FLHorizontalAlignment.right => dx + tooltipHorizontalOffset,
        FLHorizontalAlignment.left =>
          dx - tooltipWidth + tooltipHorizontalOffset,
      };
}
