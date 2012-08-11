package SetTemplateLink::Transformer;

use strict;
use File::Spec;
use Data::Dumper;

sub hdlr_template_param_edit_template {
    my ( $cb, $app, $param, $tmpl ) = @_;

    my $blog_id = $app->blog->id;
    my $plugin  = MT->component('SetTemplateLink');
    my $config_path =
      $plugin->get_config_value( 'set_template_path', "blog:$blog_id" );
    my $q           = $app->param;
    my $blog_id     = $q->param('blog_id');
    my $template_id = $q->param('id');
    my $template    = MT::Template->load($template_id);
    my $linked_file =
        $template->linked_file()
      ? $template->linked_file 
      : sub {
        my $basename = $template->identifier . '.mtml';
        return File::Spec->catfile( $config_path, $basename );
      };
    $param->{linked_file} = $linked_file if !$param->{linked_file};
}

1;
