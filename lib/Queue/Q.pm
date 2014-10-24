package Queue::Q;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.20';

1;
__END__

=head1 NAME

Queue::Q - Mix-and-match Queue Implementations and Backends

=head1 SYNOPSIS

  # Pick you queue type and a back-end:
  
  # Very primitive FIFO queue (abstract interface)
  use Queue::Q::NaiveFIFO;
  # ... and its pure-Perl, in-memory implementation
  use Queue::Q::NaiveFIFO::Perl;
  # ... its Redis-based implementation
  use Queue::Q::NaiveFIFO::Redis;
  
  # "Reliable" enqueue, claim, mark-as-done FIFO queue:
  use Queue::Q::ClaimFIFO; # abstract interface
  # ... and again, its pure-Perl, in-memory implementation
  use Queue::Q::ClaimFIFO::Perl;
  # ... and its Redis-based implementation
  use Queue::Q::ClaimFIFO::Redis;
  
  # A composite, distributed queue, built from shards of
  # the above types with weak global and strict local
  # ordering, scaling beyond single nodes.
  use Queue::Q::DistFIFO; 
  
  # Usage is somewhat similar for most queue types:
  my $queue = Queue::Q::ClaimFIFO::Redis->new(
      server      => 'redis-01',
      port        => '6379',
      queue_name  => "image_queue"
  );
  
  $q->enqueue_item( $img_url );
  
  # In another process on another machine:
  while (defined( my $item = $q->claim_item )) {
      # Do some work!
      $q->mark_item_as_done($item);
  }

  # n-ary versions exist, too:
  $q->enqueue_items( @img_urls );
  my @items = $q->claim_items(10); # 10 at a time, padded with undef
  $q->mark_items_as_done(@items);

=head1 DESCRIPTION

B<This is an experimental module. The interface may change without notice.
Before using it in production, please get in touch with the authors!>

C<Queue::Q> is a collection of queue implementations each with multiple backends.
Right now, it comes with three basic queues:

=over 2

=item L<Queue::Q::NaiveFIFO>

A naive FIFO queue C<NaiveFIFO>. Supports enqueuing data and later claiming
it in the order it was enqueued. Strict ordering, low-latency, high-throughput,
no resilience against crashing workers.

=item L<Queue::Q::ClaimFIFO>

A claim/mark-as-done FIFO queue C<ClaimFIFO>. Supports enqueuing data
(as L<Queue::Q::ClaimFIFO::Item> objects), claiming items, and keeping
track of items-being-worked-on until they are reported as done.
Strict ordering, slightly higher latency and lower throughput than the
naive FIFO queue. Resilience against crashing workers when combined with
a clean-up script that checks for old, claimed items.

=item L<Queue::Q::ReliableFIFO>

Similar interface to the C<ClaimFIFO> queue type, but only comes with a
Redis-backed implementation now. Much faster for the basic operations
then C<ClaimFIFO> since it doesn't always have to execute Lua scripts.
See L<Queue::Q::ReliableFIFO> for details.

=back

The first two basic queues come with two back-end implementations each right now:
One is a very simple, in-memory, single-process implementation L<Queue::Q::NaiveFIFO::Perl>
and L<Queue::Q::ClaimFIFO::Perl> respectively. The other is an implementation
based on Redis: L<Queue::Q::NaiveFIFO::Redis> and  L<Queue::Q::ClaimFIFO::Redis>.

As noted above, the C<ReliableFIFO> queue has a Redis-based backend only for now.

In addition to the basic queue types, the distribution contains
L<Queue::Q::DistFIFO>, an implementation of a distributed queue
that can use the basic queues as shards (but only one type of shard per
distributed queue). It supports all operations of the basic queues, but
does not enforce strict global ordering, but weak global and strict local
ordering. In an early test, two mid-range servers running multiple instances
of Redis each sustained 800k-1M transactions per second with a naive-type
distributed queue. C<DistFIFO> has not been tested with the C<ReliableFIFO>
implementation as building blocks yet!

=head1 ACKNOWLEDGMENT

This module was originally developed for Booking.com.
With approval from Booking.com, this module was generalized
and put on CPAN, for which the authors would like to express
their gratitude.

=head1 AUTHOR

Herald van der Breggen, E<lt>herald.vanderbreggen@booking.comE<gt>

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, 2013 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
